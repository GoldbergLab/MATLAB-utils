function ffsound(y, Fs, nBits)
arguments
    y {mustBeNumeric}
    Fs double = 8192
    nBits {mustBeMember(nBits, [8, 16, 24])} = 16
end

player = ffaudioplayer(y, Fs, nBits);
player.play();
delete(player);