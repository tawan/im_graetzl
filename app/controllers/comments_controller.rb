class CommentsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :set_form_id, only: [:create]

  def create
    @comment = @commentable.comments.build(comment_params)
    if @comment.save
      @commentable.create_activity :comment, owner: current_user, recipient: @comment
    else
      render nothing: true
    end
  end

  private

    def set_form_id
      @form_id = params[:form_id]
    end

    def comment_params
      params.require(:comment).permit(:content, images_files: []).merge(user_id: current_user.id)
    end
end