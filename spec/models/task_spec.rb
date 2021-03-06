require 'rails_helper'

describe Task do
  let(:project) { mock_model(Project, suppress_notifications: true) }
  let(:story)   { mock_model(Story, project: project) }

  subject(:task) { build :task, story: story }

  describe 'associations' do
    it { expect(task).to belong_to(:story) }
  end

  describe 'validations' do
    it { expect(task).to validate_presence_of(:name) }
  end

  describe '#as_json' do
    it 'returns the right keys' do
      expect(task.as_json['task'].keys.sort).to eq(%w[
                                                     created_at done id name story_id updated_at
                                                   ])
    end
  end

  describe '#to_csv' do
    context 'task completed' do
      let(:task) { build :task, story: story, name: 'task_test', done: true }
      subject { task.to_csv }

      it { is_expected.to contain_exactly(task.name, 'completed') }
    end

    context 'task not completed' do
      let(:task) { build :task, story: story, name: 'task_test', done: false }
      subject { task.to_csv }

      it { is_expected.to contain_exactly(task.name, 'not_completed') }
    end
  end

  describe '#readonly?' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:story) { create(:story, project: project, requested_by: user) }
    let(:task) { create(:task, story: story) }

    before do
      project.users << user
      project.suppress_notifications = true

      story.update_attribute(:state, 'accepted')
    end

    it "can't modify a task from a readonly story" do
      expect { task.update_attribute(:done, true) }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "can't let the task from an accepted story to be destroyed" do
      expect { task.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "can't add more tasks to an accepted story" do
      expect { story.tasks.create(name: 'test') }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it 'can destroy read_only task when deleting the project' do
      expect { project.destroy }.not_to raise_error
    end
  end
end
