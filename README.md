# DATA MINING - Discriminating eating and non-eating actions from raw sensor data

This project is a part of course requirement for Data Mining (CSE572) Class of Fall 2017. The
project is to provide solution for estimating the food intake by using the wristband sensor. The
information gathered from the wristbands were analyzed to obtain a logical conclusion regarding
when the person is eating the food and when he/she is not eating any food.

## Instructions on running code:

Copy the EMG and IMU data into EMG and IMU folder located inside "AllData" directory.
We have included our copy of Annotations since we have modified them but the raw data is too large to be included in our submission.


    %	DataParser_P4
    %   Example usage:
    %   >> parser = DataParser_P4('AllData')
    %   >> [eat_mat, noneat_mat, group_action_indices] = parser.parse_data();
    %   >> parser.export_data(eat_mat, 'eat_data.csv')
    %   >> parser.export_data(noneat_mat, 'noneat_data.csv')
    %   >> parser.export_group_mappings(group_action_indices, 'mapping.csv');
	
	% DataAnalysis (pre-requisite)
    %   >> analyzer = DataAnalysis('eat_data.csv', 'noneat_data.csv', 'mapping.csv')
    %   >> [coeff, score, latent, explained] = analyzer.analyze_pca;
    %   >> analyzer.export_pca_data('eat_pca.csv', 'noneat_pca.csv');
	
	%	DataAnalysis_DT
    %   Example Usage:
    %   >> analyzer.analyze_dt();

	
	%	DataAnalysis_SVM
    %   Example Usage:
    %   >> analyzer.analyze_svm();
	
	
	%   DataAnalysis_NN
    %   Example Usage:
    %   >> analyzer.analyze_nn();

## Project Phase 1

The first phase of the project was to collect data. Each person from a group were to go to IMPACT
lab and take video of eating some food from a designated plate. There were 4 individual portions
around four corners of the plate and the student had to pick food from each portion with total 10
cycles, each cycle containing four eating action. The process is repeated for both spoon and fork.
So there were total 40 eating action. Unique gesture such as snapping was done at the beginning
so that the beginning of the eating action can be easily identified in wristband sensors.

## Project Phase 2

The second phase of the project was to annotate the video that was taken in phase 1. The video file
was provided by TA with CSV files which had data for all eating actions. The video files were
loaded into a MATLAB tool (Labeling.m and Labeling.fig) provided by the TA/Professor. For
each eating action two frames were recorded: one when the person starts picking the food from the
plate and other when he/she completely puts it in his/her mouth. Also each eating action from each
portion was numbered as 1 for food on lower right corner, 2 for lower left corner, 3 for upper left
corner and 4 for upper right corner of the plate. The eating action numbering was repeated for each
cycles so there were 40 rows of data for each eating action of spoon and fork. Following are the
snippet directly from the annotation file for eating action spoon data.
266, 287, 1
460, 484, 2
718, 745, 3
965, 986, 4
1265, 1299, 1
1497, 1533, 2
…….
…….

## Project Phase 3

In Phase 3 of the project each group were to perform feature extraction and feature selection task.
The raw sensor data from phase 1 and video annotation data from phase 2 were used to perform
feature extraction and feature selection. Following were the tasks performed in phase 3 of project

### Task 1: Synchronization
A MATLAB code was written to extract raw data created in phase 1 and save them into two
separate classes of data: eating action class and non-eating action class. First the raw data for
sensors were synchronized with the frame data created in phase 2. The synchronization was done
by matching the last frame of video to the end time of the sensor data.
Each class of eating and non-eating action were saved into two different csv files: eat_data.csv
and noneat_data.csv. The data inside csv files were arranged in such a way that each row contained
all the data for single axis of a sensor for that individual eating or non-eating action.
Following data are directly from the eating and non-eating csv files.
Eating Action 1 Ori X -0.862 -0.861 -0.861 -0.861 -0.862 -0.864 -0.866 -0.866 -0.867 ……..
Eating Action 1 Ori Y -0.504 -0.506 -0.507 -0.507 -0.505 -0.502 -0.499 -0.498 -0.497……..
Eating Action 1 Ori Z -0.045 -0.045 -0.044 -0.042 -0.04 -0.036 -0.033 -0.03 -0.027 ……..

### Task 2: Feature Extraction

The exported data from Task 1 is initially organized into two three-dimensional matrices with
dimensions NxMxP; one matrix contains sensor data corresponding to eating actions and the other
matrix non-eating actions. Each matrix contains N unique observations/actions (2568 in our case),
M data streams for each sensor (18), and a time series of length P which represents the raw sensor
data. The actual length of the sensor data time series would vary between observations and sensors
depending on the length of the action and the sampling frequency of the device (50 Hz for IMU
and 100 Hz for EMG). Furthermore, the length of non-eating actions was typically longer than
eating actions. For this task, following feature extraction methods were selected. Please see Phase
2 report for detailed explanation of each extraction methods.
1) Variance
2) Discrete Wavelet Transform
3) Fast Fourier Transform
4) Temporal Location of Max Value
5) Windowed Mean

### Task 3: Feature Selection

In this Task we analyzed the feature extraction methods we picked in Task 2 and analyzed which
features were responsible the most variance in the data set, according to Principle Component
Analysis. PCA was certainly helpful in this scenario. We were able to reduce our feature matrix
size from Nx33 to Nx1 and still able to capture 72.5% of the variance in the combined data set.
This is important, since features with variance are required to distinguish classes. Intuitively, if a
feature has little variance (i.e. it doesn’t change), then it can’t be used to distinguish observations
because it doesn’t tell us anything. But if a feature does change and thus exhibits variance then it
can. When we used the top two principal components, we were able to capture 89.0% of the data
set with an Nx2 feature matrix

## Project Phase 4  

The new features sets obtained from Principal Component Analysis from Phase 3 is used to train
and test three different types of classifiers in Phase 4: Decision Trees, Support Vector Machines
and Neural Networks. There are three different MATLAB functions with DataAnalysis.m; one for
each classifier. MATLAB codes are submitted along with this report. There are an additional two
phases (or tasks) for Phase 4: User dependent analysis and User independent analysis. Each
MATLAB function for the corresponding classifier does both user dependent and user independent
task. The two tasks are further discussed in detail below. To proceed with the Phase 4 analysis,
eating and non eating actions for each group were mapped to a single CSV file. The csv file that
contains the eating and non eating actions for each group is saved into “mapping.csv”. MATLAB
code to generate “mapping.csv” file is inside “DataParser.m” file. Once the mapping for the
eating and non eating actions are done, PCA components are exported to the following CSV files:
“eat_pca.csv” and “noneat_pca.csv”. Data from each CSV files from PCA analysis is used to
group the data for training and testing each machine. Please refer to ReadMe.txt for the exact
commands to execute our code.



## Team Members

Following are the group member of this project
Jigar Domadia (jdomadia@asu.edu)
Joseph Campbell (jacampb1@asu.edu)
Rajrshi Raj Shrestha (rrshrest@asu.edu)
Sai Pramod Kolli (skolli6@asu.edu)


