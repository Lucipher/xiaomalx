#encoding : utf-8
class QuestionsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def index
    questions = Question.all
    if params[:new].present?
      questions = questions.order("recommend desc").order("created_at desc")
    end
    if params[:hot].present?
      questions = questions.order("answer_count desc")
    end
    questions = questions.page(params[:page]).per(params[:page_per])
    render :json => questions and return
  end

  def create
    if params[:user_id].present?
      question = Question.new
      question.title = params[:title]
      question.elder_id = params[:user_id]
      if question.save
        tag = QuestionTag.new
        tag.question_id = question.id
        tag.level_id = params[:level_id]
        tag.country_id = params[:country_id]
        tag.profe_id = params[:profe_id]
        tag.profe_children_id = params[:profe_children_id] if params[:profe_children_id].present?
        tag.other_id = params[:other_id]
        tag.save
      end
      render :json => {:result => "1"}
    else
      render :json => {:result => "0", message: '用户已退出登陆！'}
    end
  end

  def questions_tags
    tag = QuestionTag
    if params[:level_id].present?
      tag = tag.where(level_id: params[:level_id])
    end
    if params[:country_id].present?
      tag = tag.where(country_id: params[:country_id])
    end
    if params[:profe_children_id].present?
      tag = tag.where(profe_children_id: params[:profe_children_id])
    else
      if params[:profe_id].present?
        tag = tag.where(profe_id: params[:profe_id])
      end
    end
    tag_id = tag.map &:question_id if tag.present?
    if tag_id.present?
      questions = Question.where(id: tag_id)
    else
      questions = Question.all
    end
    questions = questions.order("created_at desc").page(params[:page]).per(params[:page_per])
    render :json => questions
  end

  def question_answers
    question = Question.find params[:question_id]
    question.preview = question.preview.to_i + 1
    question.save
    answers = Answer.where(question_id: params[:question_id])
    json_data = []
    if answers.present?
      answers.each do |answer|
        name = ''
        if answer.consultant.to_i == 1
          name = ConsultantUser.find(answer.object_id).name
        else
          name = Elder.find(answer.object_id).nickname
        end
        praise = Praise.find_by(answer_id: answer.id, user_id: params[:user_id]) if params[:user_id].present?
        is_praise = 0
        if praise.present?
          is_praise = 1
        end
        reply = ""
        if answer.parent.present?
          if answer.parent.consultant.to_i == 1
            reply = '回复' + ConsultantUser.find(answer.parent.object_id).name + '：' + answer.parent.title
          else
            reply = '回复' + Elder.find(answer.parent.object_id).nickname + '：' + answer.parent.title
          end
        end

        json_data << {'title' => answer.title, 'name' => name, 'user_id' => answer.object_id,
          'consultant' => answer.consultant, 'star_level' => '', 'is_praise' => is_praise,
          'praise' => answer.praises.count, 'reply' => reply, 'created_at' => answer.created_at}
      end
    end
    render :json => {questions: json_data}
  end
end
