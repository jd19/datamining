    %   TEAM MEMBERS
    %   Jigar Domadia (jdomadia@asu.edu)
    %   Joseph Campbell (jacampb1@asu.edu)
    %   Rajrshi Raj Shrestha (rrshrest@asu.edu)
    %   Sai Pramod Kolli (skolli6@asu.edu)

classdef DataParser_P4 < handle
    %DataParser_P4: Given the summary, annotations, IMU, and EMG data,
    %synchronizes and extracts the data into eat/non-eat data matrices.
    %   Example usage:
    %   >> parser = DataParser_P4('AllData')
    %   >> [eat_mat, noneat_mat, group_action_indices] = parser.parse_data();
    %   >> parser.export_data(eat_mat, 'eat_data.csv')
    %   >> parser.export_data(noneat_mat, 'noneat_data.csv')
    %   >> parser.export_group_mappings(group_action_indices, 'mapping.csv');
    %
    %   In this example, AllData is the folder given to us by the TAs
    %   containing the data from everyone.
    
    properties
        data_path
        data_summary
        eat_action_index
        noneat_action_index
    end
    
    methods
        function obj = DataParser_P4(data_path)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            obj.data_path = data_path;
            obj.data_summary = readtable(strcat(data_path, '/summary.csv'));
            obj.eat_action_index = 0;
            obj.noneat_action_index = 1;
        end
        
        function export_data(obj, data, export_path)
            sorted_data = sortrows(data, 1);
            
            file_handle = fopen(export_path, 'w');
            
            for index = 1:size(sorted_data, 1)
                fprintf(file_handle, '%s, %s', sorted_data{index, 2:3});
                fprintf(file_handle, ', %f', sorted_data{index, 4});
                fprintf(file_handle, '\n');
            end
            
            fclose(file_handle);
        end
        
        function export_group_mappings(obj, mapping, export_path)
            file_handle = fopen(export_path, 'w');
            
            for index = 1:size(mapping, 1)
                fprintf(file_handle, '%d', mapping{index}(1));
                fprintf(file_handle, ', %d', mapping{index}(2:end));
                fprintf(file_handle, '\n');
            end
            
            fclose(file_handle);
        end
        
        function [eat_mat, noneat_mat, group_action_indices] = parse_data(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %outputArg = obj.Property1 + inputArg;
            %eat_mat = csvread(obj.data_path + "/summary.csv", 1, 0, [])
            %eat_mat = xlsread(obj.data_path + "/summary.csv", "E:E");
            %noneat_mat = readtable(obj.data_path + "/summary.csv");
            %obj.data_summary('avg_frame_rate')
            %for file_name = obj.data_summary.filename'
            eat_mat = [];
            noneat_mat = [];
            group_action_indices = {};
            obj.eat_action_index = 0;
            obj.noneat_action_index = 1;
            
            for index = 1:size(obj.data_summary, 1)
                % Extract from cell and delete file extension (.mp4)
                file_name = obj.data_summary.filename(index);
                root_file_name = file_name{1}(1:end - 4);
                num_frames = obj.data_summary.nb_frames(index);
                duration = obj.data_summary.duration(index);
                
                annotation_file_name = strcat(obj.data_path, '/Annotation/', root_file_name, '.txt');
                if exist(annotation_file_name, 'file')
                    annotation_data = csvread(annotation_file_name);
                    
                    initial_eat_action_index = obj.eat_action_index;
                    initial_noneat_action_index = obj.noneat_action_index;
                    
                    [imu_eat_data, imu_noneat_data] = obj.parse_imu_data(root_file_name, annotation_data, num_frames, duration);
                    
                    if(size(imu_eat_data, 1)/10 ~= size(annotation_data, 1))
                        disp(strcat('Failed to find all annotations for: ', annotation_file_name));
                        disp(strcat('Wanted ', num2str(size(annotation_data, 1)), ' but found ', num2str(size(imu_eat_data, 1)/10)));
                    end
                    
                    disp(strcat('Num samples: ', num2str(size(imu_noneat_data, 1)/10)));
                    
                    imu_eat_action_index = obj.eat_action_index;
                    imu_noneat_action_index = obj.noneat_action_index;
                    obj.eat_action_index = initial_eat_action_index;
                    obj.noneat_action_index = initial_noneat_action_index;
                    
                    [emg_eat_data, emg_noneat_data] = obj.parse_emg_data(root_file_name, annotation_data, num_frames, duration);
                    
                    obj.eat_action_index = max(obj.eat_action_index, imu_eat_action_index);
                    obj.noneat_action_index = max(obj.noneat_action_index, imu_noneat_action_index);
                    
                    eat_mat = [eat_mat; imu_eat_data; emg_eat_data];
                    noneat_mat = [noneat_mat; imu_noneat_data; emg_noneat_data];
                    group_action_indices = [group_action_indices; initial_noneat_action_index:obj.noneat_action_index - 1];
                else
                    disp(strcat('Skipping file ', annotation_file_name));
                end
            end
        end
        
        function eat_time_stamps = get_eating_time_stamps(obj, sync_time_stamp, annotation_data, num_frames, duration)
            % Convert annotated eating frames to UNIX time stamps.
            % An eating action is the time between "begin carry"
            % and "end carry".
            eat_time_stamps = [];
            for index = 1:size(annotation_data, 1)
                start_frame = annotation_data(index, 1);
                end_frame = annotation_data(index, 2);
                
                %start_time_from_start = (start_frame / num_frames) * duration;
                %start_time_from_end = duration - start_time_from_start
                %end_time_from_start = (end_frame / num_frames) * duration;
                %end_time_from_end = duration - end_time_from_start
               
                start_time_stamp = sync_time_stamp - ((duration - ((start_frame / num_frames) * duration)) * 1000);
                end_time_stamp = sync_time_stamp - ((duration - ((end_frame / num_frames) * duration)) * 1000);
                
                if end_frame < start_frame
                   disp(strcat('Bad frames for index: ', num2str(index)));
                end
                
                if (end_frame - start_frame) > 300
                   disp(strcat('Large frame difference for index: ', num2str(index))); 
                end
                
                eat_time_stamps = [eat_time_stamps; [start_time_stamp, end_time_stamp]];
            end
        end
        
        function [imu_eat_data, imu_noneat_data] = parse_imu_data(obj, root_file_name, annotation_data, num_frames, duration)
            imu_file_name = strcat(obj.data_path, '/IMU/', root_file_name, '_IMU.txt');
            raw_imu_data = csvread(imu_file_name);
            imu_eat_data = [];
            imu_noneat_data = [];
            
            % Data feeds do not start at same time, but they end at same
            % time. So work backwards to synchronize.
            sync_time_stamp = raw_imu_data(end, 1);
            %frame_rate = num_frames / duration;
            
            disp(root_file_name);
            eat_time_stamps = obj.get_eating_time_stamps(sync_time_stamp, annotation_data, num_frames, duration);
            
            % This assumes we start in a "not eating" state, with the index
            % being incremented at the beginning of each state change. So
            % noneat_action_index purposely starts at 1.
            prev_eating = false;
            
            ori_x = [];
            ori_y = [];
            ori_z = [];
            ori_w = [];
            acc_x = [];
            acc_y = [];
            acc_z = [];
            gyro_x = [];
            gyro_y = [];
            gyro_z = [];
                
            for data_index = 1:size(raw_imu_data, 1)
                data_time_stamp = raw_imu_data(data_index, 1);
                
                eating = false;
                for eat_time_stamp_index = 1:size(eat_time_stamps, 1)
                    start_time_stamp = eat_time_stamps(eat_time_stamp_index, 1);
                    end_time_stamp = eat_time_stamps(eat_time_stamp_index, 2);
                    
                    if data_time_stamp >= start_time_stamp && data_time_stamp <= end_time_stamp
                        eating = true;
                        break
                    end
                end
                
                if(eating ~= prev_eating)
                    if(prev_eating == true)
                        imu_eat_data = [imu_eat_data; {obj.eat_action_index, strcat('Eating Action ', num2str(obj.eat_action_index)), 'Ori X', ori_x}];
                        imu_eat_data = [imu_eat_data; {obj.eat_action_index, strcat('Eating Action ', num2str(obj.eat_action_index)), 'Ori Y', ori_y}];
                        imu_eat_data = [imu_eat_data; {obj.eat_action_index, strcat('Eating Action ', num2str(obj.eat_action_index)), 'Ori Z', ori_z}];
                        imu_eat_data = [imu_eat_data; {obj.eat_action_index, strcat('Eating Action ', num2str(obj.eat_action_index)), 'Ori W', ori_w}];
                        imu_eat_data = [imu_eat_data; {obj.eat_action_index, strcat('Eating Action ', num2str(obj.eat_action_index)), 'Acc X', acc_x}];
                        imu_eat_data = [imu_eat_data; {obj.eat_action_index, strcat('Eating Action ', num2str(obj.eat_action_index)), 'Acc Y', acc_y}];
                        imu_eat_data = [imu_eat_data; {obj.eat_action_index, strcat('Eating Action ', num2str(obj.eat_action_index)), 'Acc Z', acc_z}];
                        imu_eat_data = [imu_eat_data; {obj.eat_action_index, strcat('Eating Action ', num2str(obj.eat_action_index)), 'Gyr X', gyro_x}];
                        imu_eat_data = [imu_eat_data; {obj.eat_action_index, strcat('Eating Action ', num2str(obj.eat_action_index)), 'Gyr Y', gyro_y}];
                        imu_eat_data = [imu_eat_data; {obj.eat_action_index, strcat('Eating Action ', num2str(obj.eat_action_index)), 'Gyr Z', gyro_z}];
                    else
                        imu_noneat_data = [imu_noneat_data; {obj.noneat_action_index, strcat('NonEating Action ', num2str(obj.noneat_action_index)), 'Ori X', ori_x}];
                        imu_noneat_data = [imu_noneat_data; {obj.noneat_action_index, strcat('NonEating Action ', num2str(obj.noneat_action_index)), 'Ori Y', ori_y}];
                        imu_noneat_data = [imu_noneat_data; {obj.noneat_action_index, strcat('NonEating Action ', num2str(obj.noneat_action_index)), 'Ori Z', ori_z}];
                        imu_noneat_data = [imu_noneat_data; {obj.noneat_action_index, strcat('NonEating Action ', num2str(obj.noneat_action_index)), 'Ori W', ori_w}];
                        imu_noneat_data = [imu_noneat_data; {obj.noneat_action_index, strcat('NonEating Action ', num2str(obj.noneat_action_index)), 'Acc X', acc_x}];
                        imu_noneat_data = [imu_noneat_data; {obj.noneat_action_index, strcat('NonEating Action ', num2str(obj.noneat_action_index)), 'Acc Y', acc_y}];
                        imu_noneat_data = [imu_noneat_data; {obj.noneat_action_index, strcat('NonEating Action ', num2str(obj.noneat_action_index)), 'Acc Z', acc_z}];
                        imu_noneat_data = [imu_noneat_data; {obj.noneat_action_index, strcat('NonEating Action ', num2str(obj.noneat_action_index)), 'Gyr X', gyro_x}];
                        imu_noneat_data = [imu_noneat_data; {obj.noneat_action_index, strcat('NonEating Action ', num2str(obj.noneat_action_index)), 'Gyr Y', gyro_y}];
                        imu_noneat_data = [imu_noneat_data; {obj.noneat_action_index, strcat('NonEating Action ', num2str(obj.noneat_action_index)), 'Gyr Z', gyro_z}];
                    end

                    ori_x = [];
                    ori_y = [];
                    ori_z = [];
                    ori_w = [];
                    acc_x = [];
                    acc_y = [];
                    acc_z = [];
                    gyro_x = [];
                    gyro_y = [];
                    gyro_z = [];
                    
                    if eating == true
                        obj.eat_action_index = obj.eat_action_index + 1;
                    else
                        obj.noneat_action_index = obj.noneat_action_index + 1;
                    end
                    
                end
                
                prev_eating = eating;

                ori_x = [ori_x, raw_imu_data(data_index, 2)];
                ori_y = [ori_y, raw_imu_data(data_index, 3)];
                ori_z = [ori_z, raw_imu_data(data_index, 4)];
                ori_w = [ori_w, raw_imu_data(data_index, 5)];
                acc_x = [acc_x, raw_imu_data(data_index, 6)];
                acc_y = [acc_y, raw_imu_data(data_index, 7)];
                acc_z = [acc_z, raw_imu_data(data_index, 8)];
                gyro_x = [gyro_x, raw_imu_data(data_index, 9)];
                gyro_y = [gyro_y, raw_imu_data(data_index, 10)];
                gyro_z = [gyro_z, raw_imu_data(data_index, 11)];
            end
        end
        
        function [emg_eat_data, emg_noneat_data] = parse_emg_data(obj, root_file_name, annotation_data, num_frames, duration)
            emg_file_name = strcat(obj.data_path, '/EMG/', root_file_name, '_EMG.txt');
            raw_emg_data = csvread(emg_file_name);
            emg_eat_data = [];
            emg_noneat_data = [];
            
            % Data feeds do not start at same time, but they end at same
            % time. So work backwards to synchronize.
            sync_time_stamp = raw_emg_data(end, 1);
            %frame_rate = num_frames / duration;
            
            eat_time_stamps = obj.get_eating_time_stamps(sync_time_stamp, annotation_data, num_frames, duration);
            
            % This assumes we start in a "not eating" state, with the index
            % being incremented at the beginning of each state change. So
            % noneat_action_index purposely starts at 1.
            prev_eating = false;
            
            emg_1 = [];
            emg_2 = [];
            emg_3 = [];
            emg_4 = [];
            emg_5 = [];
            emg_6 = [];
            emg_7 = [];
            emg_8 = [];
                
            for data_index = 1:size(raw_emg_data, 1)
                data_time_stamp = raw_emg_data(data_index, 1);
                
                eating = false;
                for eat_time_stamp_index = 1:size(eat_time_stamps, 1)
                    start_time_stamp = eat_time_stamps(eat_time_stamp_index, 1);
                    end_time_stamp = eat_time_stamps(eat_time_stamp_index, 2);
                    
                    if data_time_stamp >= start_time_stamp && data_time_stamp <= end_time_stamp
                        eating = true;
                        break
                    end
                end
                
                if(eating ~= prev_eating)
                    if(prev_eating == true)
                        emg_eat_data = [emg_eat_data; {obj.eat_action_index, strcat('Eating Action ', num2str(obj.eat_action_index)), 'EMG 1', emg_1}];
                        emg_eat_data = [emg_eat_data; {obj.eat_action_index, strcat('Eating Action ', num2str(obj.eat_action_index)), 'EMG 2', emg_2}];
                        emg_eat_data = [emg_eat_data; {obj.eat_action_index, strcat('Eating Action ', num2str(obj.eat_action_index)), 'EMG 3', emg_3}];
                        emg_eat_data = [emg_eat_data; {obj.eat_action_index, strcat('Eating Action ', num2str(obj.eat_action_index)), 'EMG 4', emg_4}];
                        emg_eat_data = [emg_eat_data; {obj.eat_action_index, strcat('Eating Action ', num2str(obj.eat_action_index)), 'EMG 5', emg_5}];
                        emg_eat_data = [emg_eat_data; {obj.eat_action_index, strcat('Eating Action ', num2str(obj.eat_action_index)), 'EMG 6', emg_6}];
                        emg_eat_data = [emg_eat_data; {obj.eat_action_index, strcat('Eating Action ', num2str(obj.eat_action_index)), 'EMG 7', emg_7}];
                        emg_eat_data = [emg_eat_data; {obj.eat_action_index, strcat('Eating Action ', num2str(obj.eat_action_index)), 'EMG 8', emg_8}];
                    else
                        emg_noneat_data = [emg_noneat_data; {obj.noneat_action_index, strcat('NonEating Action ', num2str(obj.noneat_action_index)), 'EMG 1', emg_1}];
                        emg_noneat_data = [emg_noneat_data; {obj.noneat_action_index, strcat('NonEating Action ', num2str(obj.noneat_action_index)), 'EMG 2', emg_2}];
                        emg_noneat_data = [emg_noneat_data; {obj.noneat_action_index, strcat('NonEating Action ', num2str(obj.noneat_action_index)), 'EMG 3', emg_3}];
                        emg_noneat_data = [emg_noneat_data; {obj.noneat_action_index, strcat('NonEating Action ', num2str(obj.noneat_action_index)), 'EMG 4', emg_4}];
                        emg_noneat_data = [emg_noneat_data; {obj.noneat_action_index, strcat('NonEating Action ', num2str(obj.noneat_action_index)), 'EMG 5', emg_5}];
                        emg_noneat_data = [emg_noneat_data; {obj.noneat_action_index, strcat('NonEating Action ', num2str(obj.noneat_action_index)), 'EMG 6', emg_6}];
                        emg_noneat_data = [emg_noneat_data; {obj.noneat_action_index, strcat('NonEating Action ', num2str(obj.noneat_action_index)), 'EMG 7', emg_7}];
                        emg_noneat_data = [emg_noneat_data; {obj.noneat_action_index, strcat('NonEating Action ', num2str(obj.noneat_action_index)), 'EMG 8', emg_8}];
                    end

                    emg_1 = [];
                    emg_2 = [];
                    emg_3 = [];
                    emg_4 = [];
                    emg_5 = [];
                    emg_6 = [];
                    emg_7 = [];
                    emg_8 = [];
                    
                    if eating == true
                        obj.eat_action_index = obj.eat_action_index + 1;
                    else
                        obj.noneat_action_index = obj.noneat_action_index + 1;
                    end
                    
                end
                
                prev_eating = eating;

                emg_1 = [emg_1, raw_emg_data(data_index, 2)];
                emg_2 = [emg_2, raw_emg_data(data_index, 3)];
                emg_3 = [emg_3, raw_emg_data(data_index, 4)];
                emg_4 = [emg_4, raw_emg_data(data_index, 5)];
                emg_5 = [emg_5, raw_emg_data(data_index, 6)];
                emg_6 = [emg_6, raw_emg_data(data_index, 7)];
                emg_7 = [emg_7, raw_emg_data(data_index, 8)];
                emg_8 = [emg_8, raw_emg_data(data_index, 9)];
            end
        end
    end
end

