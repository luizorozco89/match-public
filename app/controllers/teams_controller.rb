class TeamsController < ApplicationController
  before_action :user_is_valid
  VALID_EMAIL_REGEX = /~*@michelada.io/i.freeze

  def new
    redirect_to team_path(current_user.team) unless current_user.team.nil?
    @team = Team.new
    @name = "#{Spicy::Proton.adjective}_#{Spicy::Proton.noun}"
  end

  def create
    @team = Team.new(team_params)
    if validate_user && @team.save && current_user.update_attribute(:team, @team)
      invite_users
      flash[:notice] = t('team.messages.created')
      redirect_to main_index_path
    else
      flash[:alert] = t('team.messages.error_creating')
      render new_team_path
    end
  end

  def show
    user_has_permission
    @team = Team.find_by(id: params[:id])
    @activities = Activity.team_activities(params[:id])
    @my_activities = Activity.user_activities(current_user.id)
    @team_score = Activity.team_activities_score(params[:id])
  end

  private

  def team_params
    params.require(:team).permit(:name)
  end

  def invite_users
    user1 = params[:user_invitation_1][:email]
    user2 = params[:user_invitation_2][:email]
    team_id = current_user.team_id
    User.find_by(email: user1).update_attribute(:team_id, team_id) if User.exists?(email: user1)
    User.find_by(email: user2).update_attribute(:team_id, team_id) if User.exists?(email: user2)
    User.invite!({ email: user1 }, current_user) unless user1.empty?
    User.invite!({ email: user2 }, current_user) unless user2.empty?
  end

  def validate_user
    user1 = params[:user_invitation_1][:email]
    return false if !user1.empty? && !user1.match(VALID_EMAIL_REGEX)

    user2 = params[:user_invitation_2][:email]
    return false if !user2.empty? && !user2.match(VALID_EMAIL_REGEX)

    true
  end

  def user_is_valid
    redirect_to root_path if current_user.role == 'admin'
  end

  def user_has_permission
    return if current_user.team.id == params[:id].to_i

    flash[:alert] = t('team.error_accessing')
    redirect_to root_path
  end
end
