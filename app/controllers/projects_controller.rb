class ProjectsController < ApplicationController
  def index
    @projects = Project.order(archived_at: :asc, name: :asc).all
  end

  def new
    @project = Project.new
    @project.use_template = :basic_kanban
    if turbo_frame_request?
      render partial: "form", locals: { project: @project }
    else
      redirect_to projects_path(open_form: true)
    end
  end

  def create
    @project = Project.new(project_params)
    @project.use_template = params[:project][:use_template]

    suppressing_template_related_broadcasts do
      if @project.save
        flash[:success] = t_flash_message(@project)
        redirect_to project_issues_path(@project)
      else
        render partial: "form", locals: { project: @project }
      end
    end
  end

  def edit
    @project = Project.find(params[:id])

    if turbo_frame_request?
      render partial: "form", locals: { project: @project }
    else
      redirect_to projects_path(open_form: true, form_project_id: @project.id)
    end
  end

  def update
    @project = Project.find(params[:id])

    @updated = @project.update(project_params)
  end

  def archive
    @project = Project.find(params[:id])

    @project.archive!
  end

  def unarchive
    @project = Project.find(params[:id])

    @project.unarchive!
  end

  def destroy
    @project = Project.find(params[:id])

    if @project.destroy
      flash[:success] = t_flash_message(@project)
    else
      flash[:error] = @project.errors.full_messages.to_sentence
    end

    redirect_to projects_path
  end

  private

  # This was used in order to prevent resources created by the template
  # applier to broadcast turbo stream events.
  # That could cause UI inconsistencies when entering on a visualization
  # for the first time.
  def suppressing_template_related_broadcasts
    GroupingIssueAllocation.suppressing_turbo_broadcasts do
      Grouping.suppressing_turbo_broadcasts do
        Issue.suppressing_turbo_broadcasts do
          yield
        end
      end
    end
  end

  def project_params
    params.require(:project).permit(:name, :archived, :time_tracking_enabled)
  end
end
