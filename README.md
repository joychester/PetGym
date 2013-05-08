Requirement:  
====
Need JDK6+ and ruby-1.9.3+ installed on your Windows machine  

How To:  
====
1. Create your own repository and put all the files you downloaded from PetGym  
2. Cd to the path where PetGym.rb is  
3. Type cmd line in cmd window, for example: > PetGym.rb C:\AutoJimmy\Project_Home_Dir\Tests\Demo\PerfMon.jmx 3 1  
4. Get your detail report and summary result under Results\ folder  

PS: the PetGym need at least 1 argument which is path\to\xxx.jmx file (should under Tests\ folder by default).  
The other 2 arguments are test loop count and Test interval in seconds respectively.  

Under Conf/ folder, there is a conf_file.txt, some global wised parameter you need to predefine:  
* "jmeter_home"-- where you unzip the jmeter tool  
* "result_type"-- which kind of result type you want to look at(currently we just support aggregate type)  
* "jtl_del_flag"-- if you want to delete the .jtl temp raw data, you can turn it to true, it will save your diskspace if result set is large.  

*About Jmeter Script Naming Convention:  
====
To use this tool, when you name the Action name in your Jmeter script, Actions in a same thread group must have the same prefix( and separate by "-").  

For example, we have two thread groups,and 2 actions in each group,you can name them as following:  
   For Thread Group 1:   
   GroupName1-ActionName1  
   GroupName1-ActionName2  
   
   For Thread Group 2:   
   GroupName2-ActionName1   
   GroupName2-ActionName2      

For examlpe:    
   Thread Group1 is BRX module, you can name your actions like this:   
    BRX-LandingPage   
    BRX-SearchPage   
    BRX-EventPage  

   Thread Group2 is SLX module, you can name your actions like this:   
    SLX-LandingPage    
    SLX-SignIn   
    SLX-SignOut  

Supported PNG type result:  
====
--ResponseTimesOverTime  
--PerfMon  

Configure your PerfMon listener in your test plan :    
If you want to generate PerfMon PNG file during testing, you need to add JMeterPlugin Listener "jp@gc - PerfMon Metrics Collector" globally(which means only one listener for all test plan).  
Meanwhile, You need to save your monitoring result file under PetGym\Results folder, for example : D:\Cheng\PetGym\Results\PerfMon.jtl  

The other canidates we may support in the future, please refer to:  
http://code.google.com/p/jmeter-plugins/wiki/JMeterPluginsCMD  
