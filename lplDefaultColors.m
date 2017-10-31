function lplDefaultColors(p)
%lplDefaultColors

%  Put additional colors into the human and monkey CLUT
p.defaultParameters.display.humanCLUT(16,:) = [0 0 1];
p.defaultParameters.display.monkeyCLUT(16,:) = p.defaultParameters.display.bgColor;
p.defaultParameters.display.humanCLUT(17:25,:) = ...
     [    0    0.4470    0.7410     %  Blue
    0.8500    0.3250    0.0980      %  Orange
    0.9290    0.6940    0.1250      %  Yellow
    0.4940    0.1840    0.5560      %  Purple
    0.4660    0.6740    0.1880      %  Green
    0.3010    0.7450    0.9330      %  Cyan
    0.6350    0.0780    0.1840      %  Scarlet
    p.defaultParameters.display.bgColor        %  Gray
    1.000     0         0];         %  Red   
p.defaultParameters.display.monkeyCLUT(17:25,:) = p.defaultParameters.display.humanCLUT(17:25,:);
%p.defaultParameters.display.humanCLUT(26:34,:) = p.defaultParameters.display.humanCLUT(17:25,:);

%  For the sake of convenience define some names to references to the
%  colors.  Remember hWhite means human white whereas bWhite means both
%  white.  m{color} seems like a really bad idea.
p.defaultParameters.display.clut.hWhite = 5*[1 1 1]';
p.defaultParameters.display.clut.bWhite = 7*[1 1 1]';
p.defaultParameters.display.clut.hCyan = 8*[1 1 1]';
p.defaultParameters.display.clut.bBlack = 9*[1 1 1]';
p.defaultParameters.display.clut.hGreen = 12*[1 1 1]';
p.defaultParameters.display.clut.hRed = 13*[1 1 1]';
p.defaultParameters.display.clut.hBlack =14*[1 1 1]';
p.defaultParameters.display.clut.hBlue = 15*[1 1 1]';
p.defaultParameters.display.clut.bBlue = 16*[1 1 1]';
p.defaultParameters.display.clut.bOrange = 17*[1 1 1]';
p.defaultParameters.display.clut.bYellow = 18*[1 1 1]';
p.defaultParameters.display.clut.bPurple = 19*[1 1 1]';
p.defaultParameters.display.clut.bGreen = 20*[1 1 1]';
p.defaultParameters.display.clut.bCyan = 21*[1 1 1]';
p.defaultParameters.display.clut.bScarlet = 22*[1 1 1]';
p.defaultParameters.display.clut.bGray = 23*[1 1 1]';
p.defaultParameters.display.clut.bRed = 24*[1 1 1]';

%  Here are named colors for use in the "underlay" display pointer when
%  using the software overlay--both screens will show these. Note I haven't
%  put these in p.defaultParameters.display.clut because they are not
%  indexed colors but instead RGB triples.
p.defaultParameters.display.colors.blue = p.defaultParameters.display.humanCLUT(17,:);
p.defaultParameters.display.colors.orange = p.defaultParameters.display.humanCLUT(18,:);
p.defaultParameters.display.colors.yellow = p.defaultParameters.display.humanCLUT(19,:);
p.defaultParameters.display.colors.purple = p.defaultParameters.display.humanCLUT(20,:);
p.defaultParameters.display.colors.green = p.defaultParameters.display.humanCLUT(21,:);
p.defaultParameters.display.colors.cyan = p.defaultParameters.display.humanCLUT(22,:);
p.defaultParameters.display.colors.scarlet = p.defaultParameters.display.humanCLUT(23,:);
p.defaultParameters.display.colors.black = [0 0 0];