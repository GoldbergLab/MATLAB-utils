function loadFuture = parLoadAVData(videoPath, stdOutQueue)
    loadFuture = parfeval(@loadAVData, 2, videoPath);
end