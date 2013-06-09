require 'csv'

#need to pass at least jmeter script path from cmd para
Process::abort("Error:Please add your jmeter script path!") if ARGV.size==0;

#jmeter path para
puts $jmx_path = ARGV[0];

#running loop count
if ARGV[1] == nil
  $loop_count = 5;
else
  puts $loop_count = ARGV[1];
end

#test interval in seconds
if ARGV[2] == nil
  $sleep_in_sec = 60
else
  puts $sleep_in_sec = ARGV[2];
end

#Load current directory path where PetGym.rb is
puts $project_home = Dir.pwd.strip;

#Fetch global parameters in the Conf file
def fetch_conf_data()
  $file_data = {}
  File.open("#{$project_home}/Conf/conf_file.txt", 'r') do |file|
      file.each_line do |line|
        line_data = line.split(',')
        $file_data[line_data[0]] = line_data[1]
      end
  end
end

fetch_conf_data();
puts $jmeter_home = $file_data["jmeter_home"].strip;
$result_type = $file_data["result_type"].strip;
$jtl_del_flag = $file_data["jtl_del_flag"].strip;
$responseTimesOverTime_flag = $file_data["ResponseTimesOverTime_png"].strip
$perfMon_flag = $file_data["PerfMon_png"].strip

#extract the jmx script name
puts jmx_name = File.basename($jmx_path, ".jmx");

#create a result folder for each test under results dir
Dir.chdir("#{$project_home}/Results") { |path|
  puts $result_file_name = Time.now.strftime('%y%m%d_%H%M%S') << "_#{jmx_name}";
  Dir::mkdir($result_file_name);
}

#run .jmx tests in loops , read from args[], .jmx|loop_count|intervals(sec)
$i = 0;
$sum_report_name = "#{$project_home}/Results/#{$result_file_name}/Sum_Result.csv";
$run_once_flag = false;

while $i < $loop_count.to_i do

  jtl_file_name = "#{$project_home}/Results/#{$result_file_name}/Round_#{$i}_Raw.jtl";
  csv_file_name = "#{$project_home}/Results/#{$result_file_name}/Round_#{$i}_Agg_Result.csv";
  #put monitoring temp jtl file under results folder, remove it after generating the png file
  jtl_mon_file_name = "#{$project_home}/Results/PerfMon.jtl";

  #Jmeter test run C:/Tools/PerformanceTools/apache-jmeter-2.7
  $start_time = Time.now;
  system("#{$jmeter_home}/bin/jmeter.bat -n -t #{$jmx_path} -l #{jtl_file_name}")
  #calculate test duration in ms
  $test_duration = (Time.now - $start_time) * 10**3
  printf "Test Round <%d> duration: %d seconds\n", $i,$test_duration/1000.0
  

  #generate Aggregate report
  system("java -jar #{$jmeter_home}/lib/ext/CMDRunner.jar --tool Reporter --generate-csv #{csv_file_name} --input-jtl #{jtl_file_name} --plugin-type #{$result_type}")

  #generate PNG type result
  if $responseTimesOverTime_flag == "true"
    system("java -jar #{$jmeter_home}/lib/ext/CMDRunner.jar --tool Reporter --generate-png #{$project_home}/Results/#{$result_file_name}/Round_#{$i}.png --input-jtl #{jtl_file_name} --plugin-type ResponseTimesOverTime --width 900 --height 700");
  end

  #generate Resource monitoring PNG file, need to set up one monitoring listener in one .jmx test plan
  if $perfMon_flag == "true"
    if File.exists?(jtl_mon_file_name)
      system("java -jar #{$jmeter_home}/lib/ext/CMDRunner.jar --tool Reporter --generate-png #{$project_home}/Results/#{$result_file_name}/Round_#{$i}_monitoring.png --input-jtl #{jtl_mon_file_name} --plugin-type PerfMon --width 900 --height 700");
      
      #delete it after generating png file each round
      File.delete(jtl_mon_file_name)
    end
  end
  
  #clean up .jtl raw data files if delete flag is false
  File.delete(jtl_file_name) if ($jtl_del_flag.downcase == "true" && File.exist?(jtl_file_name));

  $i += 1;

  #Merge all CSV result files into one single sum CSV file
  #Get Thread Group name from original csv file, and just run once
  if $run_once_flag == false
    $thread_group_name = [];
    CSV.foreach("#{csv_file_name}") { |row|
      first_column = row[0].partition('-')
      if first_column[1]!= ""
        $thread_group_name << first_column[0];
      end
    }
    $thread_group_name.uniq!
    $run_once_flag = true;
  end
  
  #Write to the summary csv file by Thread Group
  CSV.open("#{$sum_report_name}", "ab") { |csv|
    csv << ["Loop_Count_#{$i}", Time.now]
    csv << [""];
    tg_seq = 0;
    $thread_group_name.count.times do
      csv << ["ThreadGroup-#{$thread_group_name[tg_seq]}"];
      csv << ["Sample Label", "Samples", "Average", "Median",	"90% Line", "Min", "Max", "Error%", "Throughput", "KB/s"]

      $total_samples = $total_response_time = $total_median = $total_perc = $total_max = $total_errs = $total_Throughput = $total_kbs = 0;
      $total_min = 100000.0;
      CSV.foreach("#{csv_file_name}") { |row|
        $row_count = 0;
        if row[0].include?("#{$thread_group_name[tg_seq]}")
          $row_count += 1;
          #append entire row to summary csv file
          csv << row;
          $total_samples += row[1].to_i;
          $total_response_time += row[2].to_f * row[1].to_i;
          $total_median += row[3].to_f * row[1].to_i;
          $total_perc += row[4].to_f * row[1].to_i;
          $total_min = row[5].to_i if row[5].to_i < $total_min
          $total_max = row[6].to_i if row[6].to_i > $total_max
          $total_errs += row[7].to_f * row[1].to_i
          $total_kbs += row[9].to_f;
        end
      }

      $total_Throughput = ($total_samples/$test_duration.to_f) * 10**3 if $test_duration > 0
      
      #calculate and append total sum line for each thread group
      csv << ["Total", "#{$total_samples}", "#{$total_response_time/$total_samples}",
        "#{$total_median/$total_samples}", "#{$total_perc/$total_samples}","#{$total_min}",
        "#{$total_max}", "#{$total_errs/$total_samples}", "#{$total_Throughput}", "#{$total_kbs}"]
      
      tg_seq += 1;
      csv << [""];
      csv << [""];
    end
    csv << [""];
  }
  sleep($sleep_in_sec.to_i);
  
end
