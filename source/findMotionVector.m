function motion = findMotionVector(video, ROI)

x0 = ROI(1);
y0 = ROI(2);
x1 = x0 + ROI(3);
y1 = y0 + ROI(4);

maxVelocity = 10;

num_frames = size(video, 4);

motion = zeros(num_frames-1, 2);

video = double(video);

for frame_num = 1:(num_frames - 1)

    ROI1 = zscore(video(y0:y1, x0:x1, :, frame_num));
    
    min_diff = inf;
    best_dx = [];
    best_dy = [];
    
    for dx = -maxVelocity:maxVelocity
        for dy = -maxVelocity:maxVelocity
            x0s = x0 + dx;
            x1s = x1 + dx;
            y0s = y0 + dy;
            y1s = y0 + dy;
            ROI2 = zscore(video(y0s:y1s, x0s:x1s, :, frame_num + 1));
            diff = sum(abs(ROI2 - ROI1), 'all') / numel(ROI1);
            if diff < min_diff
                best_dx = dx;
                best_dy = dy;
                min_diff = diff;
            end
        end
    end
    
    motion(frame_num, :) = [best_dx, best_dy];
end