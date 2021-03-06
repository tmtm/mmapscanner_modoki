require 'tempfile'
require 'mmapscanner'

describe MmapScanner do
  shared_examples_for 'MmapScanner' do
    it '#size returns size of file' do
      expect(subject.size).to eq 10000
    end
    it '#to_s returns contents of file' do
      expect(subject.to_s).to eq '0123456789'*1000
    end
    describe '#slice' do
      it 'returns MmapScanner' do
        expect(subject.slice(5, 8)).to be_instance_of MmapScanner
        expect(subject.slice(5, 8).to_s).to eq '56789012'
      end
    end
    it '#inspect returns "#<MmapScanner>"' do
      expect(subject.inspect).to eq '#<MmapScanner>'
    end
    it '#pos returns current position' do
      expect(subject.pos).to eq 0
      subject.scan(/.../)
      expect(subject.pos).to eq 3
    end
    describe '#pos=' do
      it 'change current position' do
        subject.pos = 100
        expect(subject.pos).to eq 100
      end
      it 'raise error when negative value' do
        expect{subject.pos = -1}.to raise_error(RangeError, 'out of range: -1')
      end
      it 'raise error when over size' do
        expect{subject.pos = 10001}.to raise_error(RangeError, 'out of range: 10001 > 10000')
        expect{subject.pos = 20000}.to raise_error(RangeError, 'out of range: 20000 > 10000')
      end
    end
    describe '#scan' do
      it 'returns matched data as MmapScanner' do
        ret = subject.scan(/\d{10}/)
        expect(ret.class).to eq MmapScanner
        expect(ret.to_s).to eq '0123456789'
      end
      it 'returns nil if not matched' do
        expect(subject.scan(/123/)).to be_nil
      end
      it 'forward current position' do
        subject.scan(/\d{10}/)
        expect(subject.pos).to eq 10
      end
    end
    describe '#scan_until' do
      it 'returns matched data as MmapScanner' do
        subject.scan(/012/)
        ret = subject.scan_until(/678/)
        expect(ret.class).to eq MmapScanner
        expect(ret.to_s).to eq '345678'
      end
      it 'returns nil if not matched' do
        expect(subject.scan_until(/321/)).to be_nil
      end
      it 'forward current position' do
        subject.scan_until(/456/)
        expect(subject.pos).to eq 7
      end
    end
    describe '#check' do
      it 'returns matched data as MmapScanner' do
        ret = subject.check(/\d{10}/)
        expect(ret.class).to eq MmapScanner
        expect(ret.to_s).to eq '0123456789'
      end
      it 'returns nil if not matched' do
        expect(subject.check(/123/)).to be_nil
      end
      it 'do not forward current position' do
        subject.check(/\d{10}/)
        expect(subject.pos).to eq 0
      end
    end
    describe '#check_until' do
      it 'returns matched data as MmapScanner' do
        ret = subject.check_until(/123/)
        expect(ret.class).to eq  MmapScanner
        expect(ret.to_s).to eq '0123'
      end
      it 'returns nil if not matched' do
        expect(subject.check_until(/abc/)).to be_nil
      end
      it 'do not forward current position' do
        ret = subject.check_until(/123/)
        expect(subject.pos).to eq 0
      end
    end
    describe '#skip' do
      it 'returns length of matched data' do
        expect(subject.skip(/\d{10}/)).to eq 10
      end
      it 'returns nil if not matched' do
        expect(subject.skip(/123/)).to be_nil
      end
      it 'forward current position' do
        subject.skip(/\d{10}/)
        expect(subject.pos).to eq 10
      end
    end
    describe '#skip_until' do
      it 'returns length of matched data' do
        expect(subject.skip_until(/123/)).to eq 4
      end
      it 'returns nil if not matched' do
        expect(subject.skip_until(/abc/)).to be_nil
      end
      it 'forward current position' do
          subject.skip_until(/123/)
          expect(subject.pos).to eq 4
        end
    end
    describe '#match?' do
      it 'returns length of matched data' do
        expect(subject.match?(/\d{10}/)).to eq 10
      end
      it 'returns nil if not matched' do
        expect(subject.match?(/123/)).to be_nil
      end
      it 'do not forward current position' do
        subject.match?(/\d{10}/)
        expect(subject.pos).to eq 0
      end
    end
    describe '#exist?' do
      it 'returns length of matched data' do
        expect(subject.exist?(/123/)).to eq 4
      end
      it 'returns nil if not matched' do
        expect(subject.exist?(/abc/)).to be_nil
      end
      it 'do not forward current position' do
        subject.exist?(/123/)
        expect(subject.pos).to eq 0
      end
    end
    describe '#matched' do
      it 'returns matched data after scan' do
        subject.scan(/\d{6}/)
        expect(subject.matched.to_s).to eq '012345'
      end
      it 'returns matched data after scan_until' do
        subject.scan_until(/4567/)
        expect(subject.matched.to_s).to eq '4567'
      end
      it 'returns nil if there is not matched data' do
        expect(subject.matched).to be_nil
      end
    end
    describe '#matched(nth)' do
      it 'returns nth part of matched string' do
        subject.scan(/(..)((aa)|..)(..)/)
        expect(subject.matched(0).to_s).to eq '012345'
        expect(subject.matched(1).to_s).to eq '01'
        expect(subject.matched(2).to_s).to eq '23'
        expect(subject.matched(3)).to be_nil
        expect(subject.matched(4).to_s).to eq '45'
        expect(subject.matched(5)).to be_nil
        expect(subject.matched(-1)).to be_nil
      end
    end
    describe '#peek' do
      it 'returns MmapScanner' do
        expect(subject.peek(10)).to be_instance_of MmapScanner
      end
      it 'do not forward current position' do
        subject.peek(10)
        expect(subject.pos).to eq 0
      end
    end
    describe '#eos?' do
      it 'returns true if eos' do
        subject.pos = 10000
        expect(subject.eos?).to eq true
      end
      it 'returns false if not eos' do
        subject.pos = 9999
        expect(subject.eos?).to eq false
      end
    end
    describe '#scan_full(re, true, true)' do
      it 'is same as #scan' do
        ret = subject.scan_full(/\d{10}/, true, true)
        expect(ret.class).to eq MmapScanner
        expect(ret.to_s).to eq '0123456789'
        expect(subject.pos).to eq 10
      end
    end
    describe '#scan_full(re, true, false)' do
      it 'is same as #skip' do
        ret = subject.scan_full(/\d{10}/, true, false)
        expect(ret).to eq 10
        expect(subject.pos).to eq 10
      end
    end
    describe '#scan_full(re, false, true)' do
      it 'is same as #check' do
        ret = subject.scan_full(/\d{10}/, false, true)
        expect(ret.to_s).to eq '0123456789'
        expect(subject.pos).to eq 0
      end
    end
    describe '#scan_full(re, false, false)' do
      it 'is same as #match?' do
        ret = subject.scan_full(/\d{10}/, false, false)
        expect(ret).to eq 10
        expect(subject.pos).to eq 0
      end
    end
    describe '#search_full(re, true, true)' do
      it 'is same as #scan_until' do
        ret = subject.search_full(/789/, true, true)
        expect(ret.class).to eq MmapScanner
        expect(ret.to_s).to eq '0123456789'
        expect(subject.pos).to eq 10
      end
    end
    describe '#search_full(re, true, false)' do
      it 'is same as #skip_until' do
        ret = subject.search_full(/789/, true, false)
        expect(ret).to eq 10
        expect(subject.pos).to eq 10
      end
    end
    describe '#search_full(re, false, true)' do
      it 'is same as #check_until' do
        ret = subject.search_full(/789/, false, true)
        expect(ret.to_s).to eq '0123456789'
        expect(subject.pos).to eq 0
      end
    end
    describe '#search_full(re, false, false)' do
      it 'is same as #exist?' do
        ret = subject.search_full(/789/, false, false)
        expect(ret).to eq 10
        expect(subject.pos).to eq 0
      end
    end
    describe '#rest' do
      it 'returns rest data as MmapScanner' do
        subject.pos = 9997
        ret = subject.rest
        expect(ret).to be_instance_of MmapScanner
        expect(ret.to_s).to eq '789'
      end
      it 'returns empty MmapScanner if it reached to end' do
        subject.pos = 10000
        expect(subject.rest.to_s).to eq ''
      end
    end
    describe '#terminate' do
      it 'set position to end of MmapScanner area' do
        expect(subject.terminate).to eq subject
        expect(subject.pos).to eq 10000
      end
    end
    describe '.new with position' do
      it '#size is length of rest data' do
        if src.respond_to? :size
          expect(MmapScanner.new(src, 4096).size).to eq src.size-4096
        else
          expect(MmapScanner.new(src, 4096).size).to eq File.size(src.path)-4096
        end
      end
    end
    describe '.new with length' do
      subject{MmapScanner.new(src, nil, 10)}
      it '#size is specified size' do
        expect(subject.size).to eq 10
      end
      it 'raise error when negative' do
        expect{MmapScanner.new(src, nil, -1)}.to raise_error(RangeError, 'length out of range: -1')
      end
    end
  end

  context 'with File' do
    before do
      tmpf = Tempfile.new 'mmapscanner'
      tmpf.write '0123456789'*1000
      tmpf.flush
      @file = File.open(tmpf.path)
    end
    let(:src){@file}
    subject{MmapScanner.new(src)}
    it_should_behave_like 'MmapScanner'
    context 'empty file' do
      before do
        tmpf = Tempfile.new 'mmapscanner_empty_file'
        @file = File.open(tmpf.path)
      end
      it '#size returns 0' do
        expect(subject.size).to eq 0
      end
      it '#to_s returns empty String' do
        expect(subject.to_s).to eq ''
      end
      it '#eos? returns true' do
        expect(subject.eos?).to eq true
      end
    end
  end

  context 'with String' do
    let(:src){'0123456789'*1020}
    subject{MmapScanner.new(src, 100, 10000)}
    it_should_behave_like 'MmapScanner'
    describe '.new with empty source' do
      it 'returns empty MmapScanner' do
        m = MmapScanner.new('')
        expect(m.size).to eq 0
        expect(m.to_s).to be_empty
      end
      it '#scan(//) returns empty MmapScanner' do
        m = MmapScanner.new('').scan(//)
        expect(m.size).to eq 0
      end
    end
  end

  context 'with MmapScanner' do
    before do
      tmpf = Tempfile.new 'mmapscanner'
      tmpf.write '0123456789'*1020
      tmpf.flush
      @file = File.open(tmpf.path)
    end
    let(:src){MmapScanner.new(@file)}
    subject{MmapScanner.new(src, 100, 10000)}
    it_should_behave_like 'MmapScanner'
    describe '.new with empty source' do
      it 'returns empty MmapScanner' do
        m = MmapScanner.new(src, 1020, 0)
        expect(m.size).to eq 0
        expect(m.to_s).to be_empty
      end
      it '#scan(//) returns empty MmapScanner' do
        m = MmapScanner.new(src, 1020, 0).scan(//)
        expect(m.size).to eq 0
      end
    end
  end
end
