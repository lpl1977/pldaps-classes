function p = LovejoyDefaultColors(p)
%LovejoyDefaultColors

%  Put additional colors into the human and monkey CLUT
p.trial.display.humanCLUT(16,:) = [0 0 1];
p.trial.display.monkeyCLUT(16,:) = p.trial.display.bgColor;
p.trial.display.humanCLUT(17:25,:) = ...
     [    0    0.4470    0.7410     %  Blue
    0.8500    0.3250    0.0980      %  Orange
    0.9290    0.6940    0.1250      %  Yellow
    0.4940    0.1840    0.5560      %  Purple
    0.4660    0.6740    0.1880      %  Green
    0.3010    0.7450    0.9330      %  Cyan
    0.6350    0.0780    0.1840      %  Scarlet
    p.trial.display.bgColor        %  Gray
    1.000     0         0];         %  Red   
p.trial.display.monkeyCLUT(17:25,:) = p.trial.display.humanCLUT(17:25,:);

%  For the sake of convenience define some names to references to the
%  colors.  Remember hWhite means human white whereas bWhite means both
%  white.  m{color} seems like a really bad idea.
p.trial.display.clut.hWhite = 5*[1 1 1]';
p.trial.display.clut.bWhite = 7*[1 1 1]';
p.trial.display.clut.hCyan = 8*[1 1 1]';
p.trial.display.clut.bBlack = 9*[1 1 1]';
p.trial.display.clut.hGreen = 12*[1 1 1]';
p.trial.display.clut.hRed = 13*[1 1 1]';
p.trial.display.clut.hBlack =14*[1 1 1]';
p.trial.display.clut.hBlue = 15*[1 1 1]';
p.trial.display.clut.bBlue = 16*[1 1 1]';
p.trial.display.clut.bOrange = 17*[1 1 1]';
p.trial.display.clut.bYellow = 18*[1 1 1]';
p.trial.display.clut.bPurple = 19*[1 1 1]';
p.trial.display.clut.bGreen = 20*[1 1 1]';
p.trial.display.clut.bCyan = 21*[1 1 1]';
p.trial.display.clut.bScarlet = 22*[1 1 1]';
p.trial.display.clut.bGray = 23*[1 1 1]';
p.trial.display.clut.bRed = 24*[1 1 1]';

%  Here are named colors for use in the "underlay" display pointer when
%  using the software overlay--both screens will show these.
%  Note I haven't put these in p.trial.display.clut because they are not
%  indexed colors but instead RGB triples.
p.trial.display.colors.blue = p.trial.display.humanCLUT(17,:);
p.trial.display.colors.orange = p.trial.display.humanCLUT(18,:);
p.trial.display.colors.yellow = p.trial.display.humanCLUT(19,:);
p.trial.display.colors.purple = p.trial.display.humanCLUT(20,:);
p.trial.display.colors.green = p.trial.display.humanCLUT(21,:);
p.trial.display.colors.cyan = p.trial.display.humanCLUT(22,:);
p.trial.display.colors.scarlet = p.trial.display.humanCLUT(23,:);
p.trial.display.colors.black = [0 0 0];