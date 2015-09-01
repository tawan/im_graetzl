require 'rails_helper'

RSpec.describe 'comments/_comment', type: :view do
  let(:user) { create(:user) }
  let(:comment) { build_stubbed(:comment) }

  before { sign_in user }

  describe 'edit controls' do
    context 'when comment by user' do
      before do
        allow(comment).to receive(:user) { user }
        render 'comments/comment', comment: comment
      end

      it 'displays edit controls' do
        expect(rendered).to have_selector('div.editControls')
      end
    end

    context 'when comment not by user' do
      before { render 'comments/comment', comment: comment }

      it 'does display edit controls' do
        expect(rendered).not_to have_selector('div.editControls')
      end
    end
  end

  describe 'wrapper class' do
    context 'without additional parameter' do
      before { render 'comments/comment', comment: comment }

      it 'has stream wrapper class' do
        expect(rendered).to have_selector('div.entryInitialContent')
      end

      it 'does not have inline comment' do
        expect(rendered).not_to have_selector('div.entryUserComment')
      end
    end

    context 'with additional parameter' do
      before { render 'comments/comment', comment: comment, comment_inline: true }

      it 'does not have stream wrapper class' do
        expect(rendered).not_to have_selector('div.entryInitialContent')
      end

      it 'has inline comment' do
        expect(rendered).to have_selector('div.entryUserComment')
      end
    end
  end
end