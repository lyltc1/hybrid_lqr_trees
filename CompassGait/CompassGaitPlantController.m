classdef CompassGaitPlantController < HybridDrakeSystem
    %COMPASSGAITPLANTCONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        p;
        unom;
    end

    methods
    function obj = CompassGaitPlantController(plant)
      obj = obj@HybridDrakeSystem(5,1);
       obj.p = plant;
       obj = obj.setInputFrame(plant.getStateFrame);
       obj = obj.setOutputFrame(plant.getInputFrame);
    end
    
         function u = output(obj,t,~,x)
%        if all(size(obj.unom)  == [1 1])
%         u=0; 
%         return; 
%        end
       
       
%         if (t<obj.unom.traj{1}.tspan(2))
%         u= eval(obj.unom.traj{1},t);
%         else
%         u= eval(obj.unom.traj{2},t);
%         end
      u = 0;
     end

    end
    
    methods (Static)
    function [xtraj]=run()
       plant = CompassGaitPlant();
       v= CompassGaitVisualizer(plant);
       controller = CompassGaitPlantController(plant);
       sys_closedloop = feedback(plant,controller);
       
       %p.gamma = 0;
       xtraj = simulate(sys_closedloop,[0 10],[1;0;0;2;-.4]);
       v.playback(xtraj);   
    end
    
    end

end

