require File.dirname(__FILE__) + '/test_helper'

class BucketTest < Test::Unit::TestCase  
  def test_bucket_name_validation
    valid_names   = %w(123 joe step-one step_two step3 step_4 step-5 step.six)
    invalid_names = ['12', 'jo', 'kevin spacey', 'larry@wall', '', 'a' * 256]
    validate_name = Proc.new {|name| Bucket.send(:validate_name!, name)}
    valid_names.each do |valid_name|
      assert_nothing_raised { validate_name[valid_name] }
    end
    
    invalid_names.each do |invalid_name|
      assert_raises(InvalidBucketName) { validate_name[invalid_name] }
    end
  end
  
  def test_empty_bucket
    Bucket.request_always_returns :body => Fixtures::Buckets.empty_bucket, :code => 200 do
      bucket = Bucket.find('marcel_molina')
      assert bucket.empty?
    end
  end
  
  def test_bucket_with_one_file
    Bucket.request_always_returns :body => Fixtures::Buckets.bucket_with_one_key, :code => 200 do
      bucket = Bucket.find('marcel_molina')
      assert !bucket.empty?
      assert_equal 1, bucket.size
      assert_equal %w(tongue_overload.jpg), bucket.objects.map {|object| object.key}
      assert bucket['tongue_overload.jpg']
    end
  end
  
  def test_bucket_with_more_than_one_file
    Bucket.request_always_returns :body => Fixtures::Buckets.bucket_with_more_than_one_key, :code => 200 do
      bucket = Bucket.find('marcel_molina')
      assert !bucket.empty?
      assert_equal 2, bucket.size
      assert_equal %w(beluga_baby.jpg tongue_overload.jpg), bucket.objects.map {|object| object.key}.sort
      assert bucket['tongue_overload.jpg']
    end
  end
  
  def test_bucket_path
    assert_equal '/bucket_name?max-keys=2', Bucket.send(:path, 'bucket_name', :max_keys => 2)
    assert_equal '/bucket_name', Bucket.send(:path, 'bucket_name', {})    
  end
end