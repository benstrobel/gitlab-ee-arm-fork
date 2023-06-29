#!/usr/bin/env ruby

# version can either be just the version string like "16.0.1", which will cover
# all the images with 1.0.1 in its name. Or it can be something specific like
# "GitLab EE 16.0.1 Ultimate" which will select just those images matching that
# substring.
#
# This script by default works only on private images since removing already
# published images is generally frowned upon. Private images are mostly caused
# by abrupt interruption of packer builds.

require 'aws-sdk-ec2'
require 'optparse'

def regions
  ec2_client = Aws::EC2::Client.new(credentials: Aws::Credentials.new(Gitlab::Util.get_env('AWS_ACCESS_KEY_ID'), Gitlab::Util.get_env('AWS_SECRET_ACCESS_KEY')))
  ec2_client.describe_regions.regions.map(&:region_name)
end

def deregister_amis(version, force: true)
  dry_run = !force
  version_regex = Regexp.new(version)

  puts "WARN: Dry run mode. Not actually deleting anything." if dry_run

  regions.each do |region|
    ec2_client = Aws::EC2::Client.new(region: region, credentials: Aws::Credentials.new(Gitlab::Util.get_env('AWS_ACCESS_KEY_ID'), Gitlab::Util.get_env('AWS_SECRET_ACCESS_KEY')))
    puts "Images for #{version} in region #{region}."

    paginated_images = ec2_client.describe_images(filters: [{ name: "is-public", values: ["false"] }])
    all_images = paginated_images.images

    while paginated_images.next_page?
      paginated_images = paginated_images.next_page
      all_images += paginated_images.images
    end

    images_for_version = all_images.select { |image| version_regex.match?(image.name) }
    images_for_version.each do |image|
      puts "\t * #{image.image_id} - #{image.name}"

      next if dry_run

      ec2_client.deregister_image(image_id: image.image_id) unless dry_run
    end
  end
end

options = {
  force: false
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: deregister_amis.rb [options] <version>"
  opts.on("-f", "--force", "Force deletion. False by default, causing the script to run in dry_run mode.") do |f|
    options[:force] = true
  end
end

parser.parse!

version = ARGV.pop
unless version
  warn "Version not specified."
  warn ""
  warn parser
  exit 1
end

deregister_amis(version, force: options[:force])
