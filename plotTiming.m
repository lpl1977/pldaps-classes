function plotTiming(p,indx)
%plotTiming displays timing information for frame states and flips in the
%specified trial

frameDurations = diff(p.data{indx}.timing.flipTimes(1,:));

stateChangeTimes = p.data{indx}.timing.frameStateChangeTimes(1:5,:);

subplot(2,1,1);
plot(1:length(frameDurations),1./frameDurations);
ylabel('FPS');

subplot(2,1,2);
plot(1:length(frameDurations),stateChangeTimes');
legend('frameUpdate','framePrepareDrawing','frameDraw','frameDrawingFinished','frameFlip');
xlabel('Frames');
ylabel('msec');

end

