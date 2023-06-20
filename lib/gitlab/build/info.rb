require_relative 'info/object_storage'

module Build
  class Info
    class << self
      # Fetch the package used in AWS AMIs from an S3 bucket
      def ami_deb_package_download_url(arch: 'amd64')
        folder = 'ubuntu-focal'
        folder = "#{folder}_aarch64" if arch == 'arm64'

        package_filename_url_safe = Build::Info::Package.release_version.gsub("+", "%2B")
        "https://#{Build::Info::ObjectStorage::S3.release_bucket}.#{Build::Info::ObjectStorage::S3.release_bucket_s3_endpoint}/#{folder}/#{Build::Info::Package.name}_#{package_filename_url_safe}_#{arch}.deb"
      end
    end
  end
end
