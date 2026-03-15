from tempfile import TemporaryDirectory
import numpy as np
import spikeinterface as si
import spikeinterface.preprocessing as spre
import mountainsort5 as ms5
from mountainsort5.util import create_cached_recording

recording = ... # load your recording using SpikeInterface

# Make sure the recording is preprocessed appropriately

# Note that if the recording traces are of float type, you may need to scale
# it to a reasonable voltage range in order for whitening to work properly
# recording = spre.scale(recording, gain=...)

# lazy preprocessing
recording_filtered = spre.bandpass_filter(recording, freq_min=300, freq_max=6000, dtype=np.float32)
recording_preprocessed: si.BaseRecording = spre.whiten(recording_filtered)

with TemporaryDirectory(dir='/tmp') as tmpdir:
    # cache the recording to a temporary directory for efficient reading
    recording_cached = create_cached_recording(recording_preprocessed, folder=tmpdir)

    # use scheme 1
    sorting = ms5.sorting_scheme1(
        recording=recording_cached,
        sorting_parameters=ms5.Scheme1SortingParameters(...)
    )

    # or use scheme 2
    sorting = ms5.sorting_scheme2(
        recording=recording_cached,
        sorting_parameters=ms5.Scheme2SortingParameters(...)
    )

    # or use scheme 3
    sorting = ms5.sorting_scheme3(
        recording=recording_cached,
        sorting_parameters=ms5.Scheme3SortingParameters(...)
    )

# Now you have a sorting object that you can save to disk or use for further analysis
