# frozen_string_literal: true

RSpec.shared_examples 'enqueues a job' do
  describe 'job trigger' do
    it 'enqueues the job' do
      expect { trigger }.to change(job_class, :jobs).to(
        include(a_hash_including('class' => job_class.name))
      )
    end
  end
end
