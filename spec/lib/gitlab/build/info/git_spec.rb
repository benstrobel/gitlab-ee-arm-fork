require 'spec_helper'
require 'gitlab/build/info/git'

RSpec.describe Build::Info::Git do
  before do
    stub_default_package_version

    ce_tags = "16.1.1+ce.0\n16.0.0+rc42.ce.0\n15.11.1+ce.0\n15.11.0+ce.0\n15.10.0+ce.0\n15.10.0+rc42.ce.0"
    ee_tags = "16.1.1+ee.0\n16.0.0+rc42.ee.0\n15.11.1+ee.0\n15.11.0+ee.0\n15.10.0+ee.0\n15.10.0+rc42.ee.0"
    allow(Gitlab::Util).to receive(:shellout_stdout).with(/git -c versionsort.*ce/).and_return(ce_tags)
    allow(Gitlab::Util).to receive(:shellout_stdout).with(/git -c versionsort.*ee/).and_return(ee_tags)
  end

  describe '.latest_tag' do
    context 'on CE edition' do
      before do
        stub_is_ee(false)
      end

      context 'on stable branch' do
        context 'when tags already exist in the stable version series' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '15-10-stable')
          end

          it 'returns the latest tag in the stable version series' do
            expect(described_class.latest_tag).to eq('15.10.0+ce.0')
          end
        end

        context 'when tags does not exist in the stable version series' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '16-5-stable')
          end

          it 'returns the latest available tag' do
            expect(described_class.latest_tag).to eq('16.1.1+ce.0')
          end
        end

        context 'when latest tag in the series is an RC tag' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '16-0-stable')
          end

          it 'returns the RC tag' do
            expect(described_class.latest_tag).to eq('16.0.0+rc42.ce.0')
          end
        end
      end

      context 'on feature branch' do
        before do
          stub_env_var('CI_COMMIT_BRANCH', 'my-feature-branch')
        end

        it 'returns the latest available tag' do
          expect(described_class.latest_tag).to eq('16.1.1+ce.0')
        end
      end
    end

    context 'on EE edition' do
      before do
        stub_is_ee(true)
      end

      context 'on stable branch' do
        context 'when tags already exist in the stable version series' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '15-10-stable')
          end

          it 'returns the latest tag in the stable version series' do
            expect(described_class.latest_tag).to eq('15.10.0+ee.0')
          end
        end

        context 'when tags does not exist in the stable version series' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '16-5-stable')
          end

          it 'returns the latest available tag' do
            expect(described_class.latest_tag).to eq('16.1.1+ee.0')
          end
        end

        context 'when latest tag in the series is an RC tag' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '16-0-stable')
          end

          it 'returns the RC tag' do
            expect(described_class.latest_tag).to eq('16.0.0+rc42.ee.0')
          end
        end
      end

      context 'on feature branch' do
        before do
          stub_env_var('CI_COMMIT_BRANCH', 'my-feature-branch')
        end

        it 'returns the latest available tag' do
          expect(described_class.latest_tag).to eq('16.1.1+ee.0')
        end
      end
    end
  end

  describe '.latest_stable_tag' do
    context 'on CE edition' do
      before do
        stub_is_ee(false)
      end

      context 'on stable branch' do
        context 'when tags already exist in the stable version series' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '15-10-stable')
          end

          it 'returns the latest tag in the stable version series' do
            expect(described_class.latest_stable_tag).to eq('15.10.0+ce.0')
          end
        end

        context 'when tags does not exist in the stable version series' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '16-5-stable')
          end

          it 'returns the latest available tag' do
            expect(described_class.latest_stable_tag).to eq('16.1.1+ce.0')
          end
        end

        context 'when latest tag in the series is an RC tag' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '16-0-stable')
          end

          it 'skips the RC tag and returns the latest available tag' do
            expect(described_class.latest_stable_tag).to eq('16.1.1+ce.0')
          end
        end
      end

      context 'on feature branch' do
        before do
          stub_env_var('CI_COMMIT_BRANCH', 'my-feature-branch')
        end

        it 'returns the latest available tag' do
          expect(described_class.latest_stable_tag).to eq('16.1.1+ce.0')
        end
      end
    end

    context 'on EE edition' do
      before do
        stub_is_ee(true)
      end

      context 'on stable branch' do
        context 'when tags already exist in the stable version series' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '15-10-stable')
          end

          it 'returns the latest tag in the stable version series' do
            expect(described_class.latest_stable_tag).to eq('15.10.0+ee.0')
          end
        end

        context 'when tags does not exist in the stable version series' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '16-5-stable')
          end

          it 'returns the latest available tag' do
            expect(described_class.latest_stable_tag).to eq('16.1.1+ee.0')
          end
        end

        context 'when latest tag in the series is an RC tag' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '16-0-stable')
          end

          it 'skips the RC tag and returns the latest available tag' do
            expect(described_class.latest_stable_tag).to eq('16.1.1+ee.0')
          end
        end
      end

      context 'on feature branch' do
        before do
          stub_env_var('CI_COMMIT_BRANCH', 'my-feature-branch')
        end

        it 'returns the latest available tag' do
          expect(described_class.latest_stable_tag).to eq('16.1.1+ee.0')
        end
      end
    end

    context 'when a level is specified' do
      before do
        stub_is_ee(true)
        stub_env_var('CI_COMMIT_BRANCH', 'my-feature-branch')
      end

      it 'returns recent tag at specified position' do
        expect(described_class.latest_stable_tag(level: 2)).to eq('15.11.1+ee.0')
      end
    end
  end
end
