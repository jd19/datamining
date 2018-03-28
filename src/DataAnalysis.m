classdef DataAnalysis < handle
    %DataAnalysis
    %   analyzer = DataAnalysis('eat_data.csv', 'noneat_data.csv', 'mapping.csv')
    %   [coeff, score, latent, explained] = analyzer.analyze_pca;
    
    properties
        eat_data
        noneat_data
        group_mapping_actions
        group_mapping_indices
    end
    
    methods
        function obj = DataAnalysis(eat_path_or_data, noneat_path_or_data, mapping_path_or_data)
            % This doesn't get populated if matrices are passed in
            % currently.
            obj.group_mapping_indices = {};
            
            if ischar(mapping_path_or_data)
                obj.group_mapping_actions = obj.read_mapping(mapping_path_or_data)';
            else
                obj.group_mapping_actions = mapping_path_or_data;
            end
            
            if ischar(eat_path_or_data)
                [obj.eat_data, obj.group_mapping_indices] = obj.read_data(eat_path_or_data);
            else
                obj.eat_data = eat_path_or_data;
            end
            
            if ischar(noneat_path_or_data)
                [obj.noneat_data, obj.group_mapping_indices] = obj.read_data(noneat_path_or_data);
            else
                obj.noneat_data = noneat_path_or_data;
            end
        end
        
        function mapping_indices = read_mapping(obj, csv_path)
            mapping_indices = {};
            
            csv_file = fopen(csv_path);
            
            row = fgets(csv_file);
            
            group_index = 1;
            while ischar(row)
                mapping_indices{group_index} = textscan(row, '%d', 'Delimiter', ',');
                row = fgets(csv_file);
                group_index = group_index + 1;
            end
            
            fclose(csv_file);
        end
        
        function [eat_data_all, mapping_indices] = read_data(obj, csv_path)
            eat_data_all = [];
            mapping_indices = {};
            % Read CSV file
            % Readtable doesn't appear to appreciate my CSV files.
            %eat_data_raw = readtable(csv_path, 'ReadVariableNames', false);
            csv_file = fopen(csv_path);
            % How do I want to group this?
            % Need to extract features such that I can plot them AND feed
            % them into PCA. So output features will be single matrix.
            % Input to feature extraction doesn't need to be though. So 3D
            % matrix?
            
            row = fgets(csv_file);
            eat_data_action = cell(1, 17);
            current_action_index = 1;
            previous_action_index = 1;
            
            group_index = 1;
            data_group_index = 1;
            while ischar(row)
            %while(~feof(csv_file))
                %cells = strsplit(row, ',');
                %type = textscan(csv_file, '%3c', 1);
                char_pos = 1;
                [type, char_read] = textscan(row, '%3c', 1);
                char_pos = char_pos + char_read;
                sensor = '';
                temp = {};
                
                if(strcmp(type{1}, 'Non'))
                    [temp, char_read] = textscan(row(char_pos:end), '%*13c %d, %5c, ', 1);
                else
                    [temp, char_read] = textscan(row(char_pos:end), '%*10c %d, %5c, ', 1);
                end
                
                char_pos = char_pos + char_read;
                current_action_index = temp{1};
                sensor = temp{2};
                disp(current_action_index);
                
                if(current_action_index ~= previous_action_index)
                    eat_data_all = [eat_data_all; eat_data_action];
                    eat_data_action = cell(1, 17);
                end
                
                mapping_actions = obj.group_mapping_actions{group_index};
                if(~ismember(current_action_index, mapping_actions{1}))
                    mapping_indices{group_index} = data_group_index:size(eat_data_all, 1);
                    data_group_index = size(eat_data_all, 1) + 1;
                    group_index = group_index + 1;
                end
                
                %remainder = fgetl(csv_file);
                data = textscan(row(char_pos:end), '%f', 'Delimiter', ',');
                
                switch sensor
                    case 'Ori X'
                        eat_data_action{1,1} = data{1};
                    case 'Ori Y'
                        eat_data_action{1,2} = data{1};
                    case 'Ori Z'
                        eat_data_action{1,3} = data{1};
                    case 'Ori W'
                        eat_data_action{1,4} = data{1};
                    case 'Acc X'
                        eat_data_action{1,5} = data{1};
                    case 'Acc Y'
                        eat_data_action{1,6} = data{1};
                    case 'Acc Z'
                        eat_data_action{1,7} = data{1};
                    case 'Gyr X'
                        eat_data_action{1,8} = data{1};
                    case 'Gyr Y'
                        eat_data_action{1,9} = data{1};
                    case 'Gyr Z'
                        eat_data_action{1,10} = data{1};
                    case 'EMG 1'
                        eat_data_action{1,11} = data{1};
                    case 'EMG 2'
                        eat_data_action{1,12} = data{1};
                    case 'EMG 3'
                        eat_data_action{1,13} = data{1};
                    case 'EMG 4'
                        eat_data_action{1,14} = data{1};
                    case 'EMG 5'
                        eat_data_action{1,15} = data{1};
                    case 'EMG 6'
                        eat_data_action{1,16} = data{1};
                    case 'EMG 7'
                        eat_data_action{1,17} = data{1};
                    case 'EMG 8'
                        eat_data_action{1,18} = data{1};
                end
                
                previous_action_index = current_action_index;
                
                row = fgets(csv_file);
            end
            
            % Enter last group.
            eat_data_all = [eat_data_all; eat_data_action];
            mapping_indices{group_index} = data_group_index:size(eat_data_all, 1);
            
            fclose(csv_file);
            
            mapping_indices = mapping_indices';
        end

        function [eat_fft, noneat_fft] = extract_fftcoef_emg(obj, plot)
            num_coefficients = 10;
            
            eat_fft = zeros(size(obj.eat_data, 1), num_coefficients);

            num_skipped = 0;
            for index = 1:size(obj.eat_data, 1)
                length = size(obj.eat_data{index, 11}, 1);
                if length == 0
                    num_skipped = num_skipped + 1;
                    continue
                end

                emg_data = [obj.eat_data{index, 11}, obj.eat_data{index, 12}, obj.eat_data{index, 13}, obj.eat_data{index, 14}, obj.eat_data{index, 15}, obj.eat_data{index, 16}, obj.eat_data{index, 17}, obj.eat_data{index, 18}]';
                fft_results = fft(emg_data, length, 2);
                
                two_sided = abs(fft_results/length);
                one_sided = two_sided(:, 1:floor(length/2+1));
                one_sided(:, 2:end-1) = 2 * one_sided(:, 2:end-1);
                
                combined_one_sided = sum(one_sided, 1);
                coef_indices = floor(linspace(1, floor(length/2+1), num_coefficients));
                eat_fft(index, :) = combined_one_sided(coef_indices);
            end
            
            %disp(strcat('Number of skipped samples: ', num2str(num_skipped)));
            
            if(plot)
                for index = 1:num_coefficients
                    % Only plotting low order approximations. Don't care about higher
                    % order terms.
                    figure();
                    histogram(eat_fft(1:end, index), 25);
                    title(strcat('Eat FFT Coefficient ', num2str(index)));
                    xlabel('Coefficient Value');
                    ylabel('Frequency');
                end
            end
            
            noneat_fft = zeros(size(obj.noneat_data, 1), num_coefficients);

            for index = 1:size(obj.noneat_data, 1)
                length = size(obj.noneat_data{index, 11}, 1);
                if length == 0
                    continue
                end

                emg_data = [obj.noneat_data{index, 11}, obj.noneat_data{index, 12}, obj.noneat_data{index, 13}, obj.noneat_data{index, 14}, obj.noneat_data{index, 15}, obj.noneat_data{index, 16}, obj.noneat_data{index, 17}, obj.noneat_data{index, 18}]';
                fft_results = fft(emg_data, length, 2);
                
                two_sided = abs(fft_results/length);
                one_sided = two_sided(:, 1:floor(length/2+1));
                one_sided(:, 2:end-1) = 2 * one_sided(:, 2:end-1);
                
                combined_one_sided = sum(one_sided, 1);
                coef_indices = floor(linspace(1, floor(length/2+1), num_coefficients));
                noneat_fft(index, :) = combined_one_sided(coef_indices);
            end
            
            if(plot)
                for index = 1:num_coefficients
                    % Only plotting low order approximations. Don't care about higher
                    % order terms.
                    figure();
                    histogram(noneat_fft(1:end, index), 25);
                    title(strcat('Non-Eat FFT Coefficient ', num2str(index)));
                    xlabel('Coefficient Value');
                    ylabel('Frequency');
                end
            end
        end
        
        function [eat_fft, noneat_fft] = extract_fft_emg(obj, plot)
            num_coefficients = 10;
            
            max_length_emg = 0;
            % Calculate the length of the largest IMU trajectory for both
            % eat/noneat. Note all EMG sensors have the same sampling rate,
            % so it doesn't matter which specific data stream we choose.
            for index = 1:size(obj.eat_data, 1)
                max_length_emg = max(max_length_emg, size(obj.eat_data{index, 11}, 1));
            end
            for index = 1:size(obj.noneat_data, 1)
                max_length_emg = max(max_length_emg, size(obj.noneat_data{index, 11}, 1));
            end
            
            eat_fft = zeros(size(obj.eat_data, 1), max_length_emg / 2);
            emg_sample_frequency = 100;

            domain = 0:(emg_sample_frequency/max_length_emg):(emg_sample_frequency/2-emg_sample_frequency/max_length_emg);
            for index = 1:size(obj.eat_data, 1)
                length = size(obj.eat_data{index, 11}, 1);
                if length == 0
                    continue
                end

                emg_data = [obj.eat_data{index, 11}, obj.eat_data{index, 12}, obj.eat_data{index, 13}, obj.eat_data{index, 14}, obj.eat_data{index, 15}, obj.eat_data{index, 16}, obj.eat_data{index, 17}, obj.eat_data{index, 18}]';
                fft_results = fft(emg_data, max_length_emg, 2);
                
                two_sided = abs(fft_results/max_length_emg);
                one_sided = two_sided(:, 1:max_length_emg/2+1);
                one_sided(:, 2:end-1) = 2 * one_sided(:, 2:end-1);
                
                combined_one_sided = sum(one_sided, 1);
                eat_fft(index, :) = combined_one_sided(1:max_length_emg/2);
                
                if(plot)
                    plot(domain, combined_one_sided(1:max_length_emg/2));
                    hold on
                end
            end
            
            if(plot)
                title('Amplitude spectrum of eating actions');
                xlabel('Frequency (Hz)');
                ylabel('|FFT(EMG)|');

                figure();
            end
            
            noneat_fft = zeros(size(obj.noneat_data, 1), max_length_emg / 2);

            for index = 1:size(obj.noneat_data, 1)
                length = size(obj.noneat_data{index, 11}, 1);
                if length == 0
                    continue
                end

                emg_data = [obj.noneat_data{index, 11}, obj.noneat_data{index, 12}, obj.noneat_data{index, 13}, obj.noneat_data{index, 14}, obj.noneat_data{index, 15}, obj.noneat_data{index, 16}, obj.noneat_data{index, 17}, obj.noneat_data{index, 18}]';
                fft_results = fft(emg_data, max_length_emg, 2);
                
                two_sided = abs(fft_results/max_length_emg);
                one_sided = two_sided(:, 1:max_length_emg/2+1);
                one_sided(:, 2:end-1) = 2 * one_sided(:, 2:end-1);
                
                combined_one_sided = sum(one_sided, 1);
                noneat_fft(index, :) = combined_one_sided(1:max_length_emg/2);
                
                if(plot)
                    plot(domain, combined_one_sided(1:max_length_emg/2));
                    hold on
                end
            end
            
            if(plot)
                title('Amplitude spectrum of non-eating actions');
                xlabel('Frequency (Hz)');
                ylabel('|FFT(EMG)|');
            end
            
            mean_eat_fft = mean(eat_fft, 1);
            mean_noneat_fft = mean(noneat_fft, 1);
            std_eat_fft = std(eat_fft, 0, 1);
            std_noneat_fft = std(noneat_fft, 0, 1);
            
            upper_eat_fft = mean_eat_fft + std_eat_fft;
            lower_eat_fft = mean_eat_fft - std_eat_fft;
            upper_noneat_fft = mean_noneat_fft + std_noneat_fft;
            lower_noneat_fft = mean_noneat_fft - std_noneat_fft;
            
            if(plot)
                figure();
                fill([domain, fliplr(domain)], [lower_eat_fft, fliplr(upper_eat_fft)], [204,245,255] / 255);
                hold on
                plot(domain, mean_eat_fft);
                title('Mean Eat FFT');
                ylim([0.0, 1.5]);

                figure();
                fill([domain, fliplr(domain)], [lower_noneat_fft, fliplr(upper_noneat_fft)], [204,245,255] / 255);
                hold on
                plot(domain, mean_noneat_fft);
                title('Mean Non-Eat FFT');
                ylim([0.0, 1.5]);
            end
        end
        
        function [eat_dwt, noneat_dwt] = extract_dwt_imu(obj, imu_index, plot)
            num_freq_coefficients = 5;
            
            max_length_imu = 0;
            % Calculate the length of the largest IMU trajectory for both
            % eat/noneat. Note all IMU sensors have the same sampling rate,
            % so it doesn't matter which specific data stream we choose.
            for index = 1:size(obj.eat_data, 1)
                max_length_imu = max(max_length_imu, size(obj.eat_data{index, imu_index}, 1));
            end
            for index = 1:size(obj.noneat_data, 1)
                max_length_imu = max(max_length_imu, size(obj.noneat_data{index, imu_index}, 1));
            end
            
            eat_dwt = zeros(size(obj.eat_data, 1), num_freq_coefficients);
            %imu_sample_frequency = 50;

            for index = 1:size(obj.eat_data, 1)
                length = size(obj.eat_data{index, imu_index}, 1);
                if length == 0
                    continue
                end

                [low_freq, high_freq] = dwt(obj.eat_data{index, imu_index}, 'haar');
                if(size(low_freq, 1) >= num_freq_coefficients)
                    eat_dwt(index, :) = low_freq(1:num_freq_coefficients)';
                end
            end
            
            if(plot)
                for index = 1:num_freq_coefficients
                    % Only plotting low order approximations. Don't care about higher
                    % order terms.
                    figure();
                    histogram(eat_dwt(1:end, index), 25);
                    title(strcat('Eat DWT Low Order Coefficient ', num2str(index)));
                    xlabel('Coefficient Value');
                    ylabel('Frequency');
                end
            end
         

            
            noneat_dwt = zeros(size(obj.noneat_data, 1), num_freq_coefficients);

            for index = 1:size(obj.noneat_data, 1)
                length = size(obj.noneat_data{index, imu_index}, 1);
                if length == 0
                    continue
                end
                
                [low_freq, high_freq] = dwt(obj.noneat_data{index, imu_index}, 'haar');
                if(size(low_freq, 1) >= num_freq_coefficients)
                    noneat_dwt(index, :) = low_freq(1:num_freq_coefficients)';
                end
            end
            
            if(plot)
                for index = 1:num_freq_coefficients
                    % Only plotting low order approximations. Don't care about higher
                    % order terms.
                    figure();
                    histogram(noneat_dwt(1:end, index), 25);
                    title(strcat('Non-Eat DWT Low Order Coefficient ', num2str(index)));
                    xlabel('Coefficient Value');
                    ylabel('Frequency');
                end
            end
        end
        
        function [eat_stat, noneat_stat] = extract_statistical(obj, plot)
            eat_stat = zeros(size(obj.eat_data, 1), 10);

            for index = 1:size(obj.eat_data, 1)
                length = size(obj.eat_data{index, 7}, 1);
                if length == 0
                    continue
                end
                
                for sensor_index = 1:10
                    eat_stat(index, sensor_index) = var(obj.eat_data{index, sensor_index});
                end
                
                %for sensor_index = 11:13
                %    eat_stat(index, sensor_index) = max(obj.eat_data{index, sensor_index - 3});
                %end
            end
            
            if(plot)
                for index = 1:10
                    % Only plotting low order approximations. Don't care about higher
                    % order terms.
                    figure();
                    histogram(eat_stat(1:end, index), 25);
                    title(strcat('Eat Statistical Feature ', num2str(index)));
                    xlabel('Feature Value');
                    ylabel('Frequency');
                end
            end
            
            noneat_stat = zeros(size(obj.noneat_data, 1), 10);

            for index = 1:size(obj.noneat_data, 1)
                length = size(obj.noneat_data{index, 7}, 1);
                if length == 0
                    continue
                end
                
                for sensor_index = 1:10
                    noneat_stat(index, sensor_index) = var(obj.noneat_data{index, sensor_index});
                end
                
                %for sensor_index = 11:13
                %    noneat_stat(index, sensor_index) = max(obj.noneat_data{index, sensor_index - 3});
                %end
            end
            
            if(plot)
                for index = 1:10
                    % Only plotting low order approximations. Don't care about higher
                    % order terms.
                    figure();
                    histogram(noneat_stat(1:end, index), 25);
                    title(strcat('Non-Eat Statistical Feature ', num2str(index)));
                    xlabel('Feature Value');
                    ylabel('Frequency');
                end
            end
        end
        
        function [eat_scaledstat, noneat_scaledstat] = extract_scaled_statistical(obj, plot)
            % Scale, then return mean, variance of accel.
            eat_scaledstat = zeros(size(obj.eat_data, 1), 6);

            for index = 1:size(obj.eat_data, 1)
                length = size(obj.eat_data{index, 7}, 1);
                if length == 0
                    continue
                end
                
                for sensor_index = 5:7
                    eat_scaledstat(index, sensor_index - 4) = mean(obj.eat_data{index, sensor_index} / max(abs(obj.eat_data{index, sensor_index})));
                    eat_scaledstat(index, sensor_index - 1) = var(obj.eat_data{index, sensor_index} / max(abs(obj.eat_data{index, sensor_index})));
                end
            end
            
            if(plot)
                for index = 1:6
                    figure();
                    histogram(eat_scaledstat(1:end, index), 25);
                    title(strcat('Eat Statistical Feature = ', num2str(index)));
                    xlabel('Feature Value');
                    ylabel('Frequency');
                end
            end
            
            noneat_scaledstat = zeros(size(obj.noneat_data, 1), 6);

            for index = 1:size(obj.noneat_data, 1)
                length = size(obj.noneat_data{index, 7}, 1);
                if length == 0
                    continue
                end
                
                for sensor_index = 5:7
                    noneat_scaledstat(index, sensor_index - 4) = mean(obj.noneat_data{index, sensor_index} / max(abs(obj.noneat_data{index, sensor_index})));
                    noneat_scaledstat(index, sensor_index - 1) = var(obj.noneat_data{index, sensor_index} / max(abs(obj.noneat_data{index, sensor_index})));
                end
            end
            
            if(plot)
                for index = 1:6
                    figure();
                    histogram(noneat_scaledstat(1:end, index), 25);
                    title(strcat('Non-Eat Statistical Feature = ', num2str(index)));
                    xlabel('Feature Value');
                    ylabel('Frequency');
                end
            end
        end
        
        function [eat_maxtemp, noneat_maxtemp] = extract_max_temporal(obj, plot)
            % Scale, then return position of max value from [0, 1] of
            % accel.
            eat_maxtemp = zeros(size(obj.eat_data, 1), 3);

            for index = 1:size(obj.eat_data, 1)
                length = size(obj.eat_data{index, 7}, 1);
                if length == 0
                    continue
                end
                
                for sensor_index = 5:7
                    [max_val, max_index] = max(abs(obj.eat_data{index, sensor_index}));% / max(abs(obj.eat_data{index, sensor_index}))));
                    eat_maxtemp(index, sensor_index - 4) = max_index / size(obj.eat_data{index, sensor_index}, 1);
                end
            end
            
            if(plot)
                for index = 1:3
                    figure();
                    histogram(eat_maxtemp(1:end, index), 25);
                    title(strcat('Eat Temporal Location of Max Value. Feature = ', num2str(index)));
                    xlabel('Temporal Location of Max Value');
                    ylabel('Frequency');
                end
            end
            
            noneat_maxtemp = zeros(size(obj.noneat_data, 1), 3);

            for index = 1:size(obj.noneat_data, 1)
                length = size(obj.noneat_data{index, 7}, 1);
                if length == 0
                    continue
                end
                
                for sensor_index = 5:7
                    [max_val, max_index] = max(abs(obj.noneat_data{index, sensor_index}));% / max(abs(obj.noneat_data{index, sensor_index}))));
                    noneat_maxtemp(index, sensor_index - 4) = max_index / size(obj.noneat_data{index, sensor_index}, 1);
                end
            end
            
            if(plot)
                for index = 1:3
                    figure();
                    histogram(noneat_maxtemp(1:end, index), 25);
                    title(strcat('Non-Eat Temporal Location of Max Value. Feature = ', num2str(index)));
                    xlabel('Temporal Location of Max Value');
                    ylabel('Frequency');
                end
            end
        end
        
        function [eat_movmean, noneat_movmean] = extract_moving_mean(obj, sensor_index, plot)
            % Scale, then movmean of accel.
            num_buckets = 5;
            eat_movmean = zeros(size(obj.eat_data, 1), num_buckets);

            for index = 1:size(obj.eat_data, 1)
                length = size(obj.eat_data{index, sensor_index}, 1);
                if length == 0 || length < num_buckets
                    continue
                end
                
                bucket_size = round(size(obj.eat_data{index, sensor_index}, 1) / num_buckets);
                lower_index = 1;
                upper_index = min(bucket_size, size(obj.eat_data{index, sensor_index}, 1));
                for bucket_index = 1:num_buckets
                    eat_movmean(index, bucket_index) = mean(obj.eat_data{index, sensor_index}(lower_index:upper_index));
                    lower_index = lower_index + bucket_size;
                    upper_index = min(upper_index + bucket_size, size(obj.eat_data{index, sensor_index}, 1));
                end
            end
            
            if(plot)
                for index = 1:num_buckets
                    figure();
                    histogram(eat_movmean(1:end, index), 25);
                    title(strcat('Eat Bucketed Mean. Bucket = ', num2str(index), '. Feature = ', num2str(sensor_index)));
                    xlabel('Bucket Mean');
                    ylabel('Frequency');
                end
            end
            
            noneat_movmean = zeros(size(obj.noneat_data, 1), num_buckets);

            for index = 1:size(obj.noneat_data, 1)
                length = size(obj.noneat_data{index, sensor_index}, 1);
                if length == 0
                    continue
                end
                
                bucket_size = round(size(obj.eat_data{index, sensor_index}, 1) / num_buckets);
                lower_index = 1;
                upper_index = min(bucket_size, size(obj.noneat_data{index, sensor_index}, 1));
                for bucket_index = 1:num_buckets
                    noneat_movmean(index, bucket_index) = mean(obj.noneat_data{index, sensor_index}(lower_index:upper_index));
                    lower_index = lower_index + bucket_size;
                    upper_index = min(upper_index + bucket_size, size(obj.noneat_data{index, sensor_index}, 1));
                end
            end
            
            if(plot)
                for index = 1:num_buckets
                    figure();
                    histogram(noneat_movmean(1:end, index), 25);
                    title(strcat('Non-Eat Bucketed Mean. Bucket = ', num2str(index), '. Feature = ', num2str(sensor_index)));
                    xlabel('Bucket Mean');
                    ylabel('Frequency');
                end
            end
        end
        
        function [eat_feature_matrix, noneat_feature_matrix, labels] = extract_feature_matrix(obj)
            [eat_dwt, noneat_dwt] = obj.extract_dwt_imu(7, false);
            [eat_fft, noneat_fft] = obj.extract_fftcoef_emg(false);
            [eat_stat, noneat_stat] = obj.extract_statistical(false);
            [eat_maxtemp, noneat_maxtemp] = obj.extract_max_temporal(false);
            [eat_movmean, noneat_movmean] = obj.extract_moving_mean(6, false);
            
            eat_feature_matrix = [eat_stat, eat_dwt, eat_fft, eat_maxtemp, eat_movmean];
            noneat_feature_matrix = [noneat_stat, noneat_dwt, noneat_fft, noneat_maxtemp, noneat_movmean];
            
            labels = {};
            disp('Indices of feature matrix: ');
            
            start_index = 1;
            end_index = size(eat_stat, 2);
            for index = 1:size(eat_stat, 2)
               labels{end + 1} = strcat('Var', num2str(index));
            end
            disp(strcat(num2str(start_index), ':', num2str(end_index), ' = Variance'));
            
            start_index = end_index + 1;
            end_index = end_index + size(eat_dwt, 2);
            for index = 1:size(eat_dwt, 2)
               labels{end + 1} = strcat('DWT', num2str(index));
            end
            disp(strcat(num2str(start_index), ':', num2str(end_index), ' = DWT'));
            
            start_index = end_index + 1;
            end_index = end_index + size(eat_fft, 2);
            for index = 1:size(eat_fft, 2)
               labels{end + 1} = strcat('FFT', num2str(index));
            end
            disp(strcat(num2str(start_index), ':', num2str(end_index), ' = FFT'));
            
            start_index = end_index + 1;
            end_index = end_index + size(eat_maxtemp, 2);
            for index = 1:size(eat_maxtemp, 2)
               labels{end + 1} = strcat('Temp', num2str(index));
            end
            disp(strcat(num2str(start_index), ':', num2str(end_index), ' = Temporal Location'));
            
            start_index = end_index + 1;
            end_index = end_index + size(eat_movmean, 2);
            for index = 1:size(eat_movmean, 2)
               labels{end + 1} = strcat('Mean', num2str(index));
            end
            disp(strcat(num2str(start_index), ':', num2str(end_index), ' = Windowed Mean'));
        end
        
        function [coeff, score, latent, explained] = analyze_pca(obj)
            [eat_feature_matrix, noneat_feature_matrix, labels] = obj.extract_feature_matrix();
            
            num_rows = size(eat_feature_matrix, 1);
            [coeff, score, latent, tsquared, explained, mu] = pca([eat_feature_matrix; noneat_feature_matrix]);
           
            figure();
            title('Feature Contribution to Top 2 Components');
            biplot(coeff(:, 1:2), 'varlabels', labels);
           
            for index = 1:2
                figure();
                histogram(score(1:num_rows, index), 25);
                title(strcat('Eat Projected Component = ', num2str(index)));
                xlabel('Component Value');
                ylabel('Frequency');
            end
           
            for index = 1:2
                figure();
                histogram(score(num_rows + 1:end, index), 25);
                title(strcat('Non-Eat Projected Component = ', num2str(index)));
                xlabel('Component Value');
                ylabel('Frequency');
            end
        end
        
        function export_pca_data(obj, eat_name, noneat_name)
            [eat_feature_matrix, noneat_feature_matrix, labels] = obj.extract_feature_matrix();
            
            num_rows = size(eat_feature_matrix, 1);
            [coeff, score, latent, tsquared, explained, mu] = pca([eat_feature_matrix; noneat_feature_matrix]);
            
            csvwrite(eat_name, score(1:num_rows, :));
            
            csvwrite(noneat_name, score(num_rows + 1:end, :));
        end
        
        function pca_data = read_pca_data(obj, name)
            pca_data = csvread(name);
        end
        
        function [group_eat_data, group_noneat_data] = parse_groups(obj, eat_data, noneat_data)
            group_eat_data = {};
            group_noneat_data = {};
            
            size(obj.group_mapping_indices, 1)
            for index = 1:size(obj.group_mapping_indices, 1)
                group_eat_data{index} = eat_data(obj.group_mapping_indices{index}, :);
                group_noneat_data{index} = noneat_data(obj.group_mapping_indices{index}, :);
            end
            
            group_eat_data = group_eat_data';
            group_noneat_data = group_noneat_data';
        end
        
        function analyze_dt(obj)
            eat_data = obj.read_pca_data('eat_pca.csv');
            noneat_data = obj.read_pca_data('noneat_pca.csv');
            
            [group_eat_data, group_noneat_data] = obj.parse_groups(eat_data, noneat_data);
            
            % Note: for labels, 1 = eat. 0 = non-eat.
            % This is a binary classification task.
            
            % PHASE 1 STARTS HERE: 60% of all users for train, remaining 40% of all users for test
            [train_data, test_data, train_labels, test_labels, test_mapping] = obj.get_user_dependent(group_eat_data, group_noneat_data, 0.6);
            
            num_pca_components = 5;

            %train_table = array2table([train_data, train_labels]);
            %tree = fitctree(train_table(:, 1:5), train_table.Properties.VariableNames{end});
            tree = fitctree(train_data(:, 1:num_pca_components), train_labels);
            
            truePos = 0;
            falsePos = 0;
            falseNeg = 0;
            precision = 0;
            recall = 0;
            f1 = 0;
            cnt = 0;
            
            fprintf("\n********************\n");
            fprintf("*  PHASE 1 OUTPUT  *\n");
            fprintf("********************\n\n");
            fprintf("group precision recall F1score auc");
            fprintf("\n");
            
            for group_num = 1:33
                group_data = test_data(test_mapping(group_num, 1) : test_mapping(group_num, 2), :);
                actual_label = test_labels(test_mapping(group_num, 1) : test_mapping(group_num, 2), :);
                [predicted_label, score, node, cnum] = predict(tree, group_data(:, 1:num_pca_components));
                %size(group_data)
                %fprintf("%g", size(actual_label,1));
                %fprintf("%g", size(predicted_label,1));
                %fprintf("\n");  
                %size(predicted_label)
               
                for rowCnt = 1:size(actual_label,1) 
                    %fprintf("%g", actual_label(rowCnt));
                    %fprintf("%g", predicted_label(rowCnt));
                    %fprintf("\n");
                    if(actual_label(rowCnt) == 1 && predicted_label(rowCnt) == 1)
                        truePos = truePos + 1;
                    end
                    if(actual_label(rowCnt) == 0 && predicted_label(rowCnt) == 1)
                        falsePos = falsePos + 1;
                    end                
                    if(actual_label(rowCnt) == 1 && predicted_label(rowCnt) == 0)
                        falseNeg = falseNeg + 1;
                    end              
                end                         
                
                %score(:,2)
                [fpr, tpr, threshold, areaUnderCrv] = perfcurve(actual_label, score(:,2), 1);
                figure;
                cnt = cnt + 1;
                plot(fpr,tpr)
                title("ROC Curve (User Dependent) for group " + cnt)
                xlabel('False Positive Rate')
                ylabel('True Positive Rate')
            
                fprintf("%g ", cnt);
                precision = truePos/(truePos+falsePos);
                fprintf("%g ", precision);
                recall = truePos/(truePos+falseNeg);
                fprintf("%g ", recall);           
                f1 = (2*recall*precision)/(recall + precision);
                fprintf("%g ", f1);
                fprintf("%g", areaUnderCrv);
                fprintf("\n");
            
            end
 
            %roc curve for the entire test data set
            figure();
            [t_label,score] = predict(tree,test_data(:,1:num_pca_components));
            [X,Y] = perfcurve(test_labels,score(:,2),1);
            plot(X,Y);
            xlabel("FPR");
            ylabel("TPR");
            title("roc for all group (User Dependent) for decision tree method");            
            
            figure;
            view(tree,'Mode','graph')

            % PHASE 2 STARTS HERE: 100% of 10 users for train, 100% of remaining 23 users for test
            [train_data2, test_data2, train_labels2, test_labels2, test_mapping2] = obj.get_user_independent(group_eat_data, group_noneat_data, 10);

            tree2 = fitctree(train_data2(:, 1:num_pca_components), train_labels2);
            
            truePos2 = 0;
            falsePos2 = 0;
            falseNeg2 = 0;
            precision2 = 0;
            recall2 = 0;
            f12 = 0;
            cnt2 = 0;
            
            fprintf("\n\n********************\n");
            fprintf("*  PHASE 2 OUTPUT  *\n");
            fprintf("********************\n\n");
            fprintf("group precision recall F1score auc");
            fprintf("\n");
            
            for group_num = 1:23
                group_data = test_data2(test_mapping2(group_num, 1) : test_mapping2(group_num, 2), :);
                actual_label = test_labels2(test_mapping2(group_num, 1) : test_mapping2(group_num, 2), :);
                [predicted_label, score, node, cnum] = predict(tree2, group_data(:, 1:num_pca_components));
               
                for rowCnt = 1:size(actual_label,1) 
                    %fprintf("%g", actual_label(rowCnt));
                    %fprintf("%g", predicted_label(rowCnt));
                    %fprintf("\n");
                    if(actual_label(rowCnt) == 1 && predicted_label(rowCnt) == 1)
                        truePos2 = truePos2 + 1;
                    end
                    if(actual_label(rowCnt) == 0 && predicted_label(rowCnt) == 1)
                        falsePos2 = falsePos2 + 1;
                    end                
                    if(actual_label(rowCnt) == 1 && predicted_label(rowCnt) == 0)
                        falseNeg2 = falseNeg2 + 1;
                    end              
                end                         
                
                [fpr, tpr, threshold, areaUnderCrv2] = perfcurve(actual_label, score(:,2), 1);
                figure;
                cnt2 = cnt2 + 1;
                plot(fpr,tpr)
                title("ROC Curve (User Independent) for group " + cnt2)
                xlabel('False Positive Rate')
                ylabel('True Positive Rate')
                
                fprintf("%g ", cnt2);
                precision2 = truePos2/(truePos2+falsePos2);
                fprintf("%g ", precision2);
                recall2 = truePos2/(truePos2+falseNeg2);
                fprintf("%g ", recall2);           
                f12 = (2*recall2*precision2)/(recall2 + precision2);
                fprintf("%g ", f12);
                fprintf("%g", areaUnderCrv2);
                fprintf("\n");
            end
            
            
            %roc curve for the entire test data set
            figure();
            [t_label2,score2] = predict(tree2,test_data2(:,1:num_pca_components));
            [X,Y] = perfcurve(test_labels2,score2(:,2),1);
            plot(X,Y);
            xlabel("FPR");
            ylabel("TPR");
            title("roc for all group (User Independent) for decision tree method");
            
            view(tree2,'Mode','graph')
            
            fprintf("Done");
        end
        
        function [pc] = getOptimalPCAComponents(obj)
            eat_data = obj.read_pca_data('eat_pca.csv');
            noneat_data = obj.read_pca_data('noneat_pca.csv');
            [group_eat_data, group_noneat_data] = obj.parse_groups(eat_data, noneat_data);
            sum_train_acc=zeros(1,33);
            sum_test_acc=zeros(1,33);
            for i=1:5
                [train_data, test_data, train_labels, test_labels, test_mapping] = obj.get_user_dependent(group_eat_data, group_noneat_data, 0.6);
                train_acc=[];
                test_acc=[];
                for num_pca_components = 1:33
                    SVMModel = fitcsvm(train_data(:,1:num_pca_components),train_labels);
                    [label_train,score_train] = predict(SVMModel,train_data(:,1:num_pca_components));
                    train_acc = [train_acc mean(double(train_labels == label_train)) * 100];
                    [label_test, score_test] = predict(SVMModel,test_data(:,1:num_pca_components));
                    test_acc = [test_acc mean(double(test_labels == label_test)) * 100];
                end
                sum_train_acc = sum_train_acc + train_acc;
                sum_test_acc = sum_test_acc + test_acc;
            end
            avg_train_acc = sum_train_acc/5;
            avg_test_acc = sum_test_acc/5;
            [val, pc] = max(avg_test_acc);  
            
%           run this to plot graphs too
%           plot(avg_train_acc,'DisplayName','Training Accuracy');
% 			hold on;
% 			plot(avg_test_acc,'DisplayName','Testing Accuracy');
%           legend('show');
%           title("training and test accuracy over number of components");
%           hold off;
%           figure();
%           plot(1-avg_train_acc,'DisplayName','Training Error');
%           hold on;
%           plot(1-avgg_test_acc,'DisplayName','Testing Error');
%           title("training and test accuracy over number of components");
%           hold off;

        end
        
        function [error_metric_1 error_metric_2] = analyze_svm(obj) 
            eat_data = obj.read_pca_data('eat_pca.csv');
            noneat_data = obj.read_pca_data('noneat_pca.csv');
            
            [group_eat_data, group_noneat_data] = obj.parse_groups(eat_data, noneat_data);
            
            % Note: for labels, 1 = eat. 0 = non-eat.
            % This is a binary classification task.
            
            % ASSUMPTION:
            % The data from TA does not specify which 2 files (fork/spoon)
            % belong to each group.
            % I assume that file_n and file_n+1 are from the same group
            % where n = [0,65].
            % This holds true for our group at least and results in 3
            % groups from 66 files.
            % May want to check with TA if this is really the case.
            
            % Phase 1: 60% of all users for train, remaining 40% of all users for test
            [train_data, test_data, train_labels, test_labels, test_mapping] = obj.get_user_dependent(group_eat_data, group_noneat_data, 0.6);
            %  pc = findoptimalpcacomponents(); found to be 27  
            num_pca_components = 27;

            SVMModel = fitcsvm(train_data(:,1:num_pca_components),train_labels);
			error_metric_1 = [] ;% table of error for each user

            
            fprintf("\n********************\n");
            fprintf("*  PHASE 1 OUTPUT  *\n");
            fprintf("********************\n\n");
            fprintf("group precision recall F1score auc");
            fprintf("\n");            
            
              
            for group_num = 1:33
				group_data = test_data(test_mapping(group_num, 1) : test_mapping(group_num, 2), :); 
				group_labels = test_labels(test_mapping(group_num, 1) : test_mapping(group_num, 2), :);  
				[label,score] = predict(SVMModel,group_data(:,1:num_pca_components));
				TP=0 ; FN =0 ; FP =0; TN =0;
                for i = 1:size(label,1)
                    if group_labels(i) == 1 && label(i) == 1 
						TP = TP + 1;
					elseif group_labels(i) == 1 && label(i) == 0 
						FN = FN + 1;
					elseif group_labels(i) == 0 && label(i) == 1 
						FP = FP + 1;
					elseif group_labels(i) == 0 && label(i) == 0
						TN = TN + 1;
                    end
                end	
				precision = TP / (TP + FP);
				recall = TP / (TP + FN);
				F1 = (2*precision*recall)/(precision + recall);
                
                
				TPR =  recall;
				FPR = FP/ (FP + TN);
                %roc for each group
                figure();
                [X,Y, threshold, areaUnderCrv] = perfcurve(group_labels,score(:,2),1);
                plot(X,Y);
                xlabel("FPR");
                ylabel("TPR");
                title("roc for user dependent analysis for group "+group_num);
				error_metric_1 = [error_metric_1 ; precision recall F1 TPR FPR];	
                
                fprintf("%g ", group_num);
                fprintf("%g ", precision);
                fprintf("%g ", recall);           
                fprintf("%g ", F1);
                fprintf("%g", areaUnderCrv);
                fprintf("\n");
                
                
             end
            %roc curve for the entire test data set
            figure();
            [label,score] = predict(SVMModel,test_data(:,1:num_pca_components));
            [X,Y] = perfcurve(test_labels,score(:,2),1);
            plot(X,Y);
            xlabel("FPR");
            ylabel("TPR");
            title("roc for all user dependent analysis");
            
            
            % Phase 2: 100% of 10 users for train, 100% of remaining 23 users for test
            [train_data2, test_data2, train_labels2, test_labels2, test_mapping2] = obj.get_user_independent(group_eat_data, group_noneat_data, 10);
			SVMModel = fitcsvm(train_data2(:,1:num_pca_components),train_labels2);
			error_metric_2 = []; % table of error for each user
			

            fprintf("\n\n********************\n");
            fprintf("*  PHASE 2 OUTPUT  *\n");
            fprintf("********************\n\n");
            fprintf("group precision recall F1score auc");
            fprintf("\n");            
            
            
			for group_num = 1:23
				group_data = test_data2(test_mapping2(group_num, 1) : test_mapping2(group_num, 2), :); 
				group_labels = test_labels2(test_mapping2(group_num, 1) : test_mapping2(group_num, 2), :);  
				[label2,score2] = predict(SVMModel,group_data(:,1:num_pca_components));
				TP=0 ; FN =0 ; FP =0 ; TN =0;
				for i = 1:size(label2,1)
						
					if group_labels(i) == 1 && label2(i) == 1 
						TP = TP + 1;
					elseif group_labels(i) == 1 && label2(i) == 0 
						FN = FN + 1;
					elseif group_labels(i) == 0 && label2(i) == 1 
						FP = FP + 1;
					elseif group_labels(i) == 0 && label2(i) == 0
						TN = TN + 1;
					end
				end
					
				precision = TP / (TP + FP);
				recall = TP / (TP + FN);
				F1 = (2*precision*recall)/(precision + recall);
				TPR =  recall;
				FPR = FP/ (FP + TN);
                %roc for each group
                figure();
                [X,Y, threshold, areaUnderCrv] = perfcurve(group_labels,score2(:,2),1);
                plot(X,Y);
                xlabel("FPR");
                ylabel("TPR");
                title("roc for user independent analysis for group "+group_num);
				error_metric_2 = [error_metric_2 ; precision recall F1 TPR FPR];
                
                fprintf("%g ", group_num);
                fprintf("%g ", precision);
                fprintf("%g ", recall);           
                fprintf("%g ", F1);
                fprintf("%g", areaUnderCrv);
                fprintf("\n");                
                
            end
            %roc curve
            figure();
            [label2,score2] = predict(SVMModel,test_data2(:,1:num_pca_components));
            [X,Y] = perfcurve(test_labels2,score2(:,2),1);
            plot(X,Y);
            xlabel("FPR");
            ylabel("TPR");
            title("roc for all user independent analysis");
            
        end
        
        function analyze_nn(obj)
            eat_data = obj.read_pca_data('eat_pca.csv');
            noneat_data = obj.read_pca_data('noneat_pca.csv');
            
            [group_eat_data, group_noneat_data] = obj.parse_groups(eat_data, noneat_data);
            
            % Note: for labels, 1 = eat. 0 = non-eat.
            % This is a binary classification task.
            
            % ASSUMPTION:
            % The data from TA does not specify which 2 files (fork/spoon)
            % belong to each group.
            % I assume that file_n and file_n+1 are from the same group
            % where n = [0,65].
            % This holds true for our group at least and results in 33
            % groups from 66 files.
            % May want to check with TA if this is really the case.
            
            % Phase 1: 60% of all users for train, remaining 40% of all users for test
            [train_data, test_data, train_labels, test_labels, test_mapping] = obj.get_user_dependent(group_eat_data, group_noneat_data, 0.6);
            
            % Convert labels to 1-hot encoding.
            train_labels_onehot = zeros(size(train_labels, 1), 2);
            for train_idx = 1:size(train_labels, 1)
               train_labels_onehot(train_idx, train_labels(train_idx) + 1) = 1; 
            end
            
            test_labels_onehot = zeros(size(test_labels, 1), 2);
            for test_idx = 1:size(test_labels, 1)
               test_labels_onehot(test_idx, test_labels(test_idx) + 1) = 1; 
            end
            
            fprintf("\n********************\n");
            fprintf("*  PHASE 1 OUTPUT  *\n");
            fprintf("********************\n\n");
            fprintf("group precision recall F1score auc");
            fprintf("\n");        
            
            num_pca_components = 5;
            layers = patternnet(33);
            net = train(layers, train_data(:, 1:num_pca_components)', train_labels_onehot');
            
            for group_num = 1:33
               group_data = test_data(test_mapping(group_num, 1) : test_mapping(group_num, 2), :);
               group_labels_onehot = test_labels_onehot(test_mapping(group_num, 1) : test_mapping(group_num, 2), :);
               group_labels = test_labels(test_mapping(group_num, 1) : test_mapping(group_num, 2), :);
               
               score = net(group_data(:, 1:num_pca_components)');
               perf = perform(net, group_labels_onehot', score);
               classes = vec2ind(score) - 1;
               
                TP=0 ; FN =0 ; FP =0 ; TN =0;
				for i = 1:size(classes, 2)
						
					if group_labels(i) == 1 && classes(i) == 1 
						TP = TP + 1;
					elseif group_labels(i) == 1 && classes(i) == 0 
						FN = FN + 1;
					elseif group_labels(i) == 0 && classes(i) == 1 
						FP = FP + 1;
					elseif group_labels(i) == 0 && classes(i) == 0
						TN = TN + 1;
					end
				end
					
				precision = TP / (TP + FP);
				recall = TP / (TP + FN);
				F1 = (2*precision*recall)/(precision + recall);
				TPR =  recall;
				FPR = FP/ (FP + TN);
               
                [X,Y, threshold, areaUnderCrv] = perfcurve(group_labels, score(2,:)', 1);
                fprintf("%g ", group_num);
                fprintf("%g ", precision);
                fprintf("%g ", recall);
                fprintf("%g ", F1);
                fprintf("%g", areaUnderCrv);
                fprintf("\n");
            end
            
            %roc curve for the entire test data set
            figure();
            score = net(test_data(:, 1:num_pca_components)');
            [X,Y, threshold, areaUnderCrv] = perfcurve(test_labels, score(2,:)', 1);
            plot(X,Y);
            xlabel("FPR");
            ylabel("TPR");
            title("roc for all user dependent analysis");
            
            % Phase 2: 100% of 10 users for train, 100% of remaining 23 users for test
            [train_data, test_data, train_labels, test_labels, test_mapping] = obj.get_user_independent(group_eat_data, group_noneat_data, 10);
            
            % Convert labels to 1-hot encoding.
            train_labels_onehot = zeros(size(train_labels, 1), 2);
            for train_idx = 1:size(train_labels, 1)
               train_labels_onehot(train_idx, train_labels(train_idx) + 1) = 1; 
            end
            
            test_labels_onehot = zeros(size(test_labels, 1), 2);
            for test_idx = 1:size(test_labels, 1)
               test_labels_onehot(test_idx, test_labels(test_idx) + 1) = 1; 
            end
            
            layers = patternnet(33);
            net = train(layers, train_data(:, 1:num_pca_components)', train_labels_onehot');
            
            fprintf("\n\n********************\n");
            fprintf("*  PHASE 2 OUTPUT  *\n");
            fprintf("********************\n\n");
            fprintf("group precision recall F1score auc");
            fprintf("\n");            
            
            for group_num = 1:23
               group_data = test_data(test_mapping(group_num, 1) : test_mapping(group_num, 2), :);
               group_labels_onehot = test_labels_onehot(test_mapping(group_num, 1) : test_mapping(group_num, 2), :);
               group_labels = test_labels(test_mapping(group_num, 1) : test_mapping(group_num, 2), :);
               
               score = net(group_data(:, 1:num_pca_components)');
               perf = perform(net, group_labels_onehot', score);
               classes = vec2ind(score) - 1;
               
                TP=0 ; FN =0 ; FP =0 ; TN =0;
				for i = 1:size(classes, 2)
						
					if group_labels(i) == 1 && classes(i) == 1 
						TP = TP + 1;
					elseif group_labels(i) == 1 && classes(i) == 0 
						FN = FN + 1;
					elseif group_labels(i) == 0 && classes(i) == 1 
						FP = FP + 1;
					elseif group_labels(i) == 0 && classes(i) == 0
						TN = TN + 1;
					end
				end
					
				precision = TP / (TP + FP);
				recall = TP / (TP + FN);
				F1 = (2*precision*recall)/(precision + recall);
				TPR =  recall;
				FPR = FP/ (FP + TN);
               
                [X,Y, threshold, areaUnderCrv] = perfcurve(group_labels, score(2,:)', 1);
                fprintf("%g ", group_num);
                fprintf("%g ", precision);
                fprintf("%g ", recall);
                fprintf("%g ", F1);
                fprintf("%g", areaUnderCrv);
                fprintf("\n");
            end
            
            %roc curve for the entire test data set
            figure();
            score = net(test_data(:, 1:num_pca_components)');
            [X,Y, threshold, areaUnderCrv] = perfcurve(test_labels, score(2,:)', 1);
            plot(X,Y);
            xlabel("FPR");
            ylabel("TPR");
            title("roc for all user independent analysis");
        end
        
        function [train_data, test_data, train_labels, test_labels, test_mapping] = get_user_dependent(obj, group_eat_data, group_noneat_data, ratio_train)
            train_data = [];
            test_data = [];
            train_labels = [];
            test_labels = [];
            test_mapping = [];
            
            % 1 group = 1 user
            % Iterate every group. Grab 60% of eat/non-eat data and throw
            % it in train.
            % Take remaining 40% and throw it in test.
            % Keep classification labels consistent.
            % 1 = eat. 0 = non-eat.
            % Note that the increment step is 2.
            % This is because 2 consecutive "groups"
            % are actually the same group (due to fork/spoon file split).

            for group_index = 1:2:size(group_eat_data, 1)
                group_all_data = [group_eat_data{group_index}; group_noneat_data{group_index}; group_eat_data{group_index + 1}; group_noneat_data{group_index + 1}];
                group_all_labels = [ones(size(group_eat_data{group_index}, 1), 1); zeros(size(group_noneat_data{group_index}, 1), 1); ones(size(group_eat_data{group_index + 1}, 1), 1); zeros(size(group_noneat_data{group_index + 1}, 1), 1)];
                
                num_data = size(group_all_data, 1);
                train_indices = randsample(num_data, floor(num_data * ratio_train));
                test_indices = setdiff(1:num_data, train_indices)';
                
                %test_mapping = [test_mapping; [size(test_data, 1) + 1, size(test_indices, 1)]];
                test_mapping = [test_mapping; [size(test_data, 1) + 1, size(test_data, 1)+size(test_indices, 1)]];
                train_data = [train_data; group_all_data(train_indices, :)];
                test_data = [test_data; group_all_data(test_indices, :)];
                train_labels = [train_labels; group_all_labels(train_indices, :)];
                test_labels = [test_labels; group_all_labels(test_indices, :)];
            end
        end
        
        function [train_data, test_data, train_labels, test_labels, test_mapping] = get_user_independent(obj, group_eat_data, group_noneat_data, num_users_train)
            train_data = [];
            test_data = [];
            train_labels = [];
            test_labels = [];
            test_mapping = [];
            
            % 1 group = 1 user
            % Iterate 10 groups. Grab 100% of eat/non-eat data and throw
            % it in train.
            % Take 100% of remaining 23 groups and throw it in test.
            % Keep classification labels consistent.
            % 1 = eat. 0 = non-eat.
            % Note that the increment step is 2.
            % This is because 2 consecutive "groups"
            % are actually the same group (due to fork/spoon file split).

            train_indices = randsample(floor(size(group_eat_data, 1) / 2), num_users_train);
            test_indices = setdiff(1:floor(size(group_eat_data, 1) / 2), train_indices)';
            prev=0;flag =0;
            
            for group_index = 1:2:size(group_eat_data, 1)
                group_all_data = [group_eat_data{group_index}; group_noneat_data{group_index}; group_eat_data{group_index + 1}; group_noneat_data{group_index + 1}];
                group_all_labels = [ones(size(group_eat_data{group_index}, 1), 1); zeros(size(group_noneat_data{group_index}, 1), 1); ones(size(group_eat_data{group_index + 1}, 1), 1); zeros(size(group_noneat_data{group_index + 1}, 1), 1)];
                %{
                if(ismember(floor(group_index / 2), train_indices))
                    train_data = [train_data; group_all_data(:, :)];
                    train_labels = [train_labels; group_all_labels(:, :)];
                else
                    test_data = [test_data; group_all_data(:, :)];
                    test_labels = [test_labels; group_all_labels(:, :)];
                end
                %}
                
                if(ismember(ceil(group_index / 2), train_indices))
                    train_data = [train_data; group_all_data(:, :)];
                    train_labels = [train_labels; group_all_labels(:, :)];
                else
                    if flag == 0
                        test_mapping = [test_mapping;  [1, size(group_all_data,1)]];
                        prev = size(group_all_data,1);
                        flag = 1;
                    else
                        test_mapping = [test_mapping; [(prev +1) , (prev + size(group_all_data,1))]];
                        prev = prev + size(group_all_data,1);
                    end
                    test_data = [test_data; group_all_data(:, :)];
                    test_labels = [test_labels; group_all_labels(:, :)];
                end                
                
                
                
            end
        end        
    end
    
end

