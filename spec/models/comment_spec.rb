require 'rails_helper'

RSpec.describe Comment, type: :model do

  it 'has a valid factory' do
    expect(build_stubbed(:comment)).to be_valid
  end

  describe 'associations' do
    let(:comment) { create(:comment) }

    it 'has user' do
      expect(comment).to respond_to(:user)      
    end

    it 'has commentables' do
      expect(comment).to respond_to(:commentable)      
    end

    it 'has images' do
      expect(comment).to respond_to(:images)      
    end

    describe 'destroy associated records' do
      before do
        3.times { create(:image, imageable: comment) }
      end

      it 'has images' do
        expect(comment.images.count).to eq(3)
      end

      it 'destroys images' do
        images = comment.images
        comment.destroy
        images.each do |image|
          expect(Image.find_by_id(image.id)).to be_nil
        end
      end
    end
  end

  describe 'scopes' do
    describe 'default scope' do
      let!(:older_comment) { create(:comment, created_at: 1.day.ago) }
      let!(:newer_comment) { create(:comment, created_at: 1.hour.ago) }

      it 'retrieves newer_comment before older_comment' do
        expect(Comment.all).to eq([newer_comment, older_comment])
      end
    end
  end

  describe 'validations' do
    it 'is invalid without content' do
      expect(build(:comment, content: '')).not_to be_valid
    end
  end
end
