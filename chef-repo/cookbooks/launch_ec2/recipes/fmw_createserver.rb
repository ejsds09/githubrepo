# Cookbook Name:: launch_ec2
# Recipe:: default
#
# Copyright 2015, Accenture
#
# All rights reserved - Do Not Redistribute
#

if node['jenkins_server_instance_name'].empty?
	ruby_block "CHECK_JENKINS_PARAMETER" do
		block do
			puts "\n\nINFO: DB_NAME Field is empty"
			puts "INFO: This Job will not create a Database Server\n\n"
		end
	end
else

	node['jenkins_server_instance_name'].each do |instance_name|
	node['security_group'].each do |security_group|
	node['subnet_id'].each do |subnet_id|
	node['availability_zone'].each do |availability_zone|
	
	require 'mixlib/shellout'
	
	ruby_block "CREATE_EC2_INSTANCE" do
			block do\
			
			#ENV['PATH'] = "#{node['fmw_aws']['user']['home']}/bin:/opt/chefdk/embedded/bin:/root/.chefdk/gem/ruby/2.1.0/bin:/sbin:/bin:/usr/sbin:/usr/bin"
			#system("echo PATH = $PATH")
			
			
			$INSTANCE_ID=`aws ec2 run-instances --image-id #{node[:launch_ec2][:server][:ami]} --count #{node[:launch_ec2][:server][:count]} --instance-type #{node[:launch_ec2][:server][:type]}  \
			--placement AvailabilityZone=#{availability_zone} --security-group-ids #{security_group} --subnet-id #{subnet_id} \
			--key-name #{node[:launch_ec2][:server][:keyname]} | grep INSTANCES | awk '{print $7}'`
			
			instanceid="#{$INSTANCE_ID.strip}"
			
					$STAT='pending'
					while "#{$STAT}" == "pending" do
						puts "\nWAITING: Creating #{instanceid}"
						sleep 5
						$STAT=`aws ec2 describe-instances --instance-id #{instanceid} | grep STATE | awk '{print $3}'`
					end
					
					puts "SUCCESS: EC2 Instance #{instanceid} was created from AMI #{node[:launch_ec2][:server][:ami]}"
					puts "Instance Availability Zone: #{node[:launch_ec2][:server][:availability_zone]}"
					puts "Instance Type: #{node[:launch_ec2][:server][:type]}"
					puts "Instance Security Group: #{node[:launch_ec2][:server][:sgi]}"
					puts "Instance Subnet ID: #{node[:launch_ec2][:server][:subnetid]}"
			
			puts "\nTagging #{instanceid} with NAME #{instance_name}"
			system("aws ec2 create-tags --resources #{instanceid} --tags Key=Name,Value=#{instance_name}")
			
			#Insert the instance ID to the server_id.txt file
			#This will be used for checking the instance status (system ans instance check)
			File.open("#{node[:launch_ec2][:config][:server_instance]}", 'w+') { |f|
				f.puts "#{instanceid}"
			}

			$INSTANCEIP=`aws ec2 describe-instances --instance-ids #{instanceid} | grep PRIVATEIPADDRESSES |  awk '{print $4}'`
			#remove the extra whirespace
			instanceip="#{$INSTANCEIP.strip}"
			puts "\nIPADDRESS #{instanceip}"

		end
		end
		end
		end
	end
	end
end