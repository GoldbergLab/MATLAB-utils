function isoluminantVideoData = makeVideoIsoluminant(videoData)

meanValue = mean(videoData, 'all');
frameMeans = mean(videoData, [1, 2]);
adjustmentFactor = meanValue / frameMeans;
isoluminantVideoData = uint8(round(double(videoData) .* adjustmentFactor));