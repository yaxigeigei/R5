
vid = videoinput('gige', 1, 'Mono8');
src = getselectedsource(vid);

vid.ROIPosition = [ 0, 0, 640, 480 ];
src.PacketSize = 8000;
src.PacketDelay = 0;

framesToAcquire = 2000;
framesPerSecond = CalculateFrameRate(vid, framesToAcquire)

frameTarget = 120;
if framesPerSecond > frameTarget
    framesPerSecond = frameTarget;
end
delay = CalculatePacketDelay(vid, framesPerSecond)

src.PacketDelay = delay;

