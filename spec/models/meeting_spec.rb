require 'rails_helper'

RSpec.describe Meeting, type: :model do
  
  it 'has a valid factory' do
    expect(build_stubbed(:meeting)).to be_valid
  end

  describe 'validations' do
    it 'invalid without name' do
      expect(build(:meeting, name: nil)).not_to be_valid
    end

    it 'invalid without graetzl' do
      expect(build(:meeting, graetzl: nil)).not_to be_valid
    end

    it 'invalid with starts_at_date in past' do
      expect(build(:meeting, starts_at_date: 1.day.ago)).not_to be_valid
    end

    it 'invalid with ends_at_time before_starts_at_time' do
      expect(build(:meeting, starts_at_date: Date.today, starts_at_time: Time.now + 1.hour, ends_at_time: Time.now)).not_to be_valid
    end
  end

  describe 'attributes' do
    let(:meeting) { create(:meeting) }

    it 'has cover_photo' do
      expect(meeting).to respond_to(:cover_photo)
    end

    it 'has cover_photo_content_type' do
      expect(meeting).to respond_to(:cover_photo_content_type)
    end
  end


  describe 'associations' do
    let(:meeting) { create(:meeting) }

    it 'has graetzl' do
      expect(meeting).to respond_to(:graetzl)
    end    

    it 'has location' do
      expect(meeting).to respond_to(:location)
    end

    it 'has address' do
      expect(meeting).to respond_to(:address)      
    end

    it 'has going_tos' do
      expect(meeting).to respond_to(:going_tos)
    end

    it 'has users' do
      expect(meeting).to respond_to(:users)      
    end

    it 'has comments' do
      expect(meeting).to respond_to(:comments)      
    end

    it 'has categories' do
      expect(meeting).to respond_to(:categories)      
    end

    describe 'destroy associated records' do
      describe 'comments' do
        before { 3.times { create(:comment, commentable: meeting) } }

        it 'has comments' do
          expect(meeting.comments.count).to eq(3)
        end

        it 'destroys comments' do
          comments = meeting.comments
          meeting.destroy
          comments.each do |comment|
            expect(Comment.find_by_id(comment.id)).to be_nil
          end
        end
      end

      describe 'going_tos' do
        before { 3.times { create(:going_to, meeting: meeting) } }

        it 'has going_tos' do
          expect(meeting.going_tos.count).to eq(3)
        end

        it 'destroys going_tos' do
          going_tos = meeting.going_tos
          meeting.destroy
          going_tos.each do |going_to|
            expect(GoingTo.find_by_id(going_to.id)).to be_nil
          end
        end
      end

      describe 'address' do
        before { create(:address, addressable: meeting) }

        it 'has address' do
          expect(meeting.address).not_to be_nil
        end

        it 'destroys address' do
          address = meeting.address
          meeting.destroy
          expect(Address.find_by_id(address.id)).to be_nil
        end
      end
    end
  end

  describe 'scopes' do
    let!(:m_today) { create(:meeting, starts_at_date: Date.today) }
    let!(:m_tomorrow) { create(:meeting, starts_at_date: Date.tomorrow) }
    let!(:m_after_tomorrow) { create(:meeting, starts_at_date: Date.tomorrow+1) }
    let!(:m_nil) { create(:meeting, starts_at_date: nil) }
    let(:m_yesterday) { build(:meeting, starts_at_date: Date.yesterday) }
    before { m_yesterday.save(validate: false) }

    describe 'default scope (starts_at_date: :asc)' do
      subject(:meetings) { Meeting.all }

      it 'retrieves earliest first, nil last' do
        expect(meetings.to_a).to eq [m_yesterday, m_today, m_tomorrow, m_after_tomorrow, m_nil]
      end

      it 'ignores :created_at order' do
        m_today.update(created_at: Date.yesterday-1)
        m_after_tomorrow.update(created_at: Date.yesterday)
        expect(meetings.to_a).to eq [m_yesterday, m_today, m_tomorrow, m_after_tomorrow, m_nil]
      end
    end

    describe 'upcoming' do
      subject(:meetings) { Meeting.upcoming }

      it 'retrieves nearest first, nil last' do
        expect(meetings.to_a).to eq [m_today, m_tomorrow, m_after_tomorrow, m_nil]
      end

      it 'excludes past' do
        expect(meetings).not_to include(m_yesterday)
      end

      it 'ignores :created_at order' do
        m_today.update(created_at: Date.yesterday-1)
        m_after_tomorrow.update(created_at: Date.yesterday)

        expect(meetings.to_a).to eq [m_today, m_tomorrow, m_after_tomorrow, m_nil]
      end
    end

    describe 'past' do
      let(:m_1_before_yesterday) { build(:meeting, starts_at_date: Date.yesterday-1) }
      let(:m_2_before_yesterday) { build(:meeting, starts_at_date: Date.yesterday-2) }
      before do
        m_1_before_yesterday.save(validate: false)
        m_2_before_yesterday.save(validate: false)
      end
      subject(:meetings) { Meeting.past }

      it 'retrieves past' do
        expect(meetings).to include(m_yesterday, m_1_before_yesterday, m_2_before_yesterday)
      end

      it 'excludes upcoming' do
        expect(meetings).not_to include(m_today, m_tomorrow, m_after_tomorrow)        
      end

      it 'excludes nil' do
        expect(meetings).not_to include(m_nil)        
      end

      it 'orders starts_at_date: :desc (anti default_scope)' do
        puts meetings.map(&:starts_at_date)
        expect(meetings).to eq [m_2_before_yesterday, m_1_before_yesterday, m_yesterday]
      end
    end
  end

  describe '#upcoming?' do
    let(:meeting) { build_stubbed(:meeting) }

    context 'without starts_at_date' do

      it 'has no starts_at_date' do
        expect(meeting.starts_at_date).to be_falsey
      end

      it 'returns true' do
        expect(meeting.upcoming?).to be_truthy
      end
    end

    context 'with starts_at_date in future' do
      before { meeting.starts_at_date = Date.tomorrow }
      
      it 'has starts_at_date' do
        expect(meeting.starts_at_date).to be_truthy
      end

      it 'returns true' do
        expect(meeting.upcoming?).to be_truthy
      end
    end

    context 'with starts_at_date in past' do
      before { meeting.starts_at_date = Date.yesterday }
      
      it 'has starts_at_date' do
        expect(meeting.starts_at_date).to be_truthy
      end

      it 'returns true' do
        expect(meeting.upcoming?).to be_falsey
      end
    end
  end
  

  describe '#past?' do
    let(:meeting) { build_stubbed(:meeting) }

    context 'without starts_at_date' do

      it 'has no starts_at_date' do
        expect(meeting.starts_at_date).to be_falsey
      end

      it 'returns true' do
        expect(meeting.past?).to be_falsey
      end
    end

    context 'with starts_at_date in future' do
      before { meeting.starts_at_date = Date.tomorrow }
      
      it 'has starts_at_date' do
        expect(meeting.starts_at_date).to be_truthy
      end

      it 'returns true' do
        expect(meeting.past?).to be_falsey
      end
    end

    context 'with starts_at_date in past' do
      before { meeting.starts_at_date = Date.yesterday }
      
      it 'has starts_at_date' do
        expect(meeting.starts_at_date).to be_truthy
      end

      it 'returns true' do
        expect(meeting.past?).to be_truthy
      end
    end
  end

  # describe '#initator' do
  #   let(:meeting) { create(:meeting) }
  #   let(:initiator) { create(:user) }

  #   context 'when present' do
  #     before { create(:going_to, meeting: meeting, user: initiator, role: GoingTo.roles[:initiator]) }

  #     it 'returns user' do
  #       expect(meeting.initiator).to eq initiator
  #     end
  #   end

  #   context 'when multiple present' do
  #     before do
  #       create(:going_to, meeting: meeting, role: GoingTo.role[:initiator])
  #       create(:going_to, meeting: meeting, user: initiator, role: GoingTo.roles[:initiator])
  #     end

  #     it 'returns last user' do
  #       expect(meeting.initiator).to eq initiator
  #     end
  #   end

  #   context 'when not present' do
  #     before do
  #       create(:going_to, meeting: meeting)
  #     end

  #     it 'returns nil' do
  #       expect(meeting.initiator).to be_nil
  #     end
  #   end
  # end
end