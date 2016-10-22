//INF_Mike64's Skyhook system 1.7
/*USAGE
Im happy for you to change it but you must credit me as original author.

To initalise execVM "Skyhook.sqf"; init.sqf (NOT MP tested yet)
Any object wanting to have a skyhook add this to init : this setVariable ["SKM",["P",30,50,true,1,""],true];
Any vehicles wanting to catch add this  to init: _catcher setVariable ["SKM_Catcher",1,true];
*/
/* SKM Variable [
State,
Lenght,
Hit Zone,
Light,
Texture,
ActionID
]
example this setVariable ["SKM",["P",30,50,true,1,""],true];

SKM_OBJ Variable [
_para,
_para2,
_Flare,
_Flare2,
_link,
_Balrope,
_catcher
]
SKM_Catcher
*/


SKM_Init = {
//Setup of Actions
{ if(typeName ((_x getVariable "SKM")select 5) != "SCALAR") then {[_x] call SKM_AddAction;};} foreach allMissionObjects "All";; //Units
};

SKM_AddAction = {
	// mp issues may occure
	ls = (_this select 0) addAction ["Launch Skyhook", {[(_this select 0)] Call SKM_Action}];
	(_this select 0) setVariable ["SKM",["P",
	(((_this select 0) getVariable "SKM") select 1), //Rope Length 
	(((_this select 0) getVariable "SKM") select 2), //Hit Zone
	(((_this select 0) getVariable "SKM") select 3), //Light
	(((_this select 0) getVariable "SKM") select 4), //Texture
	ls],true];
};

SKM_UpdateState = {
	//Update Variable
	(_this select 0) setVariable ["SKM",[(_this select 1),
	(((_this select 0) getVariable "SKM") select 1), //Rope Length 
	(((_this select 0) getVariable "SKM") select 2), //Hit Zone
	(((_this select 0) getVariable "SKM") select 3), //Light
	(((_this select 0) getVariable "SKM") select 4), //Texture
	(((_this select 0) getVariable "SKM") select 5) //Action
	],true];
	//Update Action
	_String = "Error";
	switch (_this select 1) do {
	case "P":{_String = "Launch Skyhook";};
	case "D":{(_this select 0) removeaction (((_this select 0) getVariable "SKM") select 5);};
	case "AT":{_String = "Release Load";};
	default {_String = "Dismantle Skyhook";};
};
	(_this select 0) setUserActionText [(((_this select 0) getVariable "SKM") select 5),_String];
};
SKM_Action = {
	_item = (_this select 0);
	_param = (_this select 0) getVariable "SKM";
	switch (_param select 0) do {
		case "P":{[(_this select 0)] call SKM_Launch;};
		case "AT":{[(_this select 0)] call SKM_Release;};
		default {[(_this select 0)] call SKM_Pack;};
	};
};
SKM_Launch = {
   
	private["_Cargo", "_Catcher", "_RopeL", "_HitZone", "_Lightz","_Tex"];
	_Textures = ["","balloon.paa","balloonOng.paa"];
	_param = (_this select 0) getVariable "SKM";
	_Scargo = (_this select 0);
	_ropelenght = _param select 1;
	_hitz = _param select 2;
	_light = _param select 3;
	_tex =  _Textures select(_param select 4);
	_balloon = "O_Parachute_02_F";
	 if(lineIntersects [[getposASL _Scargo select 0 ,getposASL _Scargo select 1,(getposASL _Scargo select 2) + 5],[getposASL _Scargo select 0 ,getposASL _Scargo select 1,(getposASL _Scargo select 2) + 100]] || vehicle _Scargo != _Scargo) exitWith { hint "Sky is not clear";};
		[_Scargo,"U"] call SKM_UpdateState;
	
	_para = _balloon createVehicle(position _Scargo);
	_para2 = _balloon createVehicle(position _Scargo);
	
	if(_tex != "") then {
		_para setObjectTextureGlobal [0,_tex];
		_para2 setObjectTextureGlobal [0,_tex];
	};
	_para2 attachto[_para, [0, 0, 48]];
	_para2 setDir(getDir _para) + 45;
	_para2 setVectorUp[0, 0, -1];
	_Flare = "";
	_Flare2 = "";
	//Lights
	if (_light) then {
		_light = "Chemlight_Red";
		_Flare = _light createVehicle(position _para);
		_Flare attachto[_para, [0, 0, 0]];
		_Flare2 = _light createVehicle(position _para);
		_Flare2 attachto[_para, [0, 0, 25]];
	};

	_link = "Skeet_Clay_F"
	createVehicle(position _Scargo);
	_link setObjectTextureGlobal [0,""];
	_link disableCollisionWith _Scargo;
	if (_Scargo isKindOf 'Man') then {
		_link attachto[_Scargo, [0, 0, 0],"spine3"];
	} else {
		_link attachto[_Scargo, [0, 0, 0]];
	};
	_para enableRopeAttach true;
	_link enableRopeAttach true;
	_Balrope = ropeCreate[_para, [0, 0, 0], _link, [0, 0, 0], _ropelenght];

	_x = 2;
	_Scargo setVariable ["SKM_OBJ",
	[_para,
	_para2,
	_Flare,
	_Flare2,
	_link,
	_Balrope],true];
	sleep 5;

	while {
		_x < _ropelenght
	}
	do {
		_para setPos(_Scargo modelToWorldVisual [0, 0, _x]);
		_x = _x + 0.075;
		sleep 0.01;
		if (((_Scargo getVariable "SKM")select 0) in ["D","P"]) exitWith {};
	};
	if (((_Scargo getVariable "SKM")select 0) in ["D","P"]) exitWith {};
	detach _link;
	[_Scargo] call SKM_Wait;
};
SKM_Wait = {
	_Scargo = (_this select 0);
	_obs = (_this select 0) getVariable "SKM_OBJ";
	_para =  _obs select 0;
	_link = _obs select 4;
	_param = (_this select 0) getVariable "SKM";
	_hitz = _param select 2;
	_ropelenght = _param select 1;
	//Waiting Loop
	_wait = 1;
	while {
		_wait == 1;
	}
	do {
	{ if(_para distance _x <= _hitz && (_x getVariable "SKM_Catcher") == 1 && isnull (getSlingLoad _x)) exitWith  {
	_catcher = _x;
	_wait = 0;
	_Scargo setVariable ["SKM_OBJ",
	[(((_this select 0) getVariable "SKM_OBJ") select 0),
	(((_this select 0) getVariable "SKM_OBJ") select 1),
	(((_this select 0) getVariable "SKM_OBJ") select 2),
	(((_this select 0) getVariable "SKM_OBJ") select 3),
	(((_this select 0) getVariable "SKM_OBJ") select 4),
	(((_this select 0) getVariable "SKM_OBJ") select 5),
	_catcher],true];
	} } foreach vehicles; 
		_para setPos(_Scargo modelToWorldVisual [0, 0, _ropelenght]);
		if (_Scargo isKindOf 'Man') then {
			_link setPos(_Scargo modelToWorldVisual (_Scargo selectionPosition "spine3"));
		} else {
			_link setPos(_Scargo modelToWorldVisual [0, 0, 0]);
		};
		if (((_Scargo getVariable "SKM")select 0) in ["D","P"]) exitWith {};
	};
	if (((_Scargo getVariable "SKM")select 0) in ["D","P"]) exitWith {};
	//In zone
	_prev = _Scargo distance _catcher;
	_pending = 1;
	while { _pending == 1 } do {
	 if(_Scargo distance _catcher <= _prev) then {
	 _prev = _Scargo distance _catcher;
	 } else {
	 _pending = 2;
	 };
	 _para setPos(_Scargo modelToWorldVisual [0, 0, _ropelenght]);
		if (_Scargo isKindOf 'Man') then {
			_link setPos(_Scargo modelToWorldVisual [0, 0, 1.5]);
		} else {
			_link setPos(_Scargo modelToWorldVisual [0, 0, 0]);
		};
		if (((_Scargo getVariable "SKM")select 0) in ["D","P"]) exitWith {};
	};
	if (((_Scargo getVariable "SKM")select 0) in ["D","P"]) exitWith {};
	[_Scargo] call SKM_Hook;
};

SKM_Hook = {
	_Scargo = (_this select 0);
	_obs = (_this select 0) getVariable "SKM_OBJ";
	_Balrope = _obs select 5;
	_para2 = _obs select 1;
	_link = _obs select 4;
	_catcher = _obs select 6;
	//Hooking
	ropeDestroy _Balrope;
	deleteVehicle _para2;
    _link setPos(_Scargo modelToWorldVisual (_Scargo selectionPosition "spine3"));
	_Liftrope = ropeCreate[_catcher, [0, 0, -1], _link, [0, 0, 0], (_catcher distance _link)];
	ropeUnwind[_Liftrope, 5, 0.5];
	while { ((_catcher distance _link) - (ropeLength _Liftrope) <= 4)} do {
	sleep 0.1;
	};
	if (_Scargo isKindOf 'Man') then {
	_link setmass ((loadAbs _Scargo) + ((90*2.2)/0.1));
		_Scargo setVectorUp[0, 0, 0.25];
		_Scargo switchMove  "passenger_injured_medevac_truck01";
		_link setPos(_Scargo modelToWorldVisual (_Scargo selectionPosition "spine3"));
		_Scargo attachto[_link,[0,0.46,-0.2] ];
	 } else {
		_link setmass (getmass _Scargo);
		_link setPos(_Scargo modelToWorldVisual [0, 0, 0]);
		_Scargo attachto[_link, [0, 0, 0]];
	 };
	
	while {
		_Scargo distance _catcher > 4
	}
	do {

		if (!(_link in (ropeAttachedObjects _catcher))) exitWith {
			if (_Scargo isKindOf 'Man' && alive _Scargo) then {
				_Scargo switchMove "HaloFreeFall_non";
			};
			detach _Scargo;
			if ((getPosATL _Scargo select 2) < 0) then { _Scargo setPosATL [(getPosATL _Scargo select 0) ,(getPosATL _Scargo select 1),0];};
				[_Scargo,"D"] call SKM_UpdateState;
		};
	};
	if (!(_link in (ropeAttachedObjects _catcher))) exitWith {};
	[_Scargo] Call SKM_CargoLoad;
};

SKM_CargoLoad = {
	
	_Scargo = (_this select 0);
	_obs = (_this select 0) getVariable "SKM_OBJ";
	_link = _obs select 4;
	_catcher = _obs select 6;
	//Move to cargo
	deleteVehicle _link;
	detach _Scargo;
	if (_Scargo isKindOf 'Man') then {
		_Scargo switchMove "";
		_Scargo moveincargo _catcher;
		sleep 0.5;
		_Scargo moveincargo _catcher;
		_Scargo enableRopeAttach false;
		[_Scargo,"D"] call SKM_UpdateState;
	} else {
		if (_catcher canSlingLoad _Scargo) then {
			_catcher setSlingLoad _Scargo;
			[_Scargo,"D"] call SKM_UpdateState;
		} else {
			_Scargo attachto[_catcher, [0, 0, -5]];
			_catcher setVariable ["SKM_Catcher",2,true];
			[_Scargo,"AT"] call SKM_UpdateState;
		};
	};
};

//Break away.
SKM_Pack = {
	private["_Cargo","_Link","_Para","_Para2"];
	_obs = (_this select 0) getVariable "SKM_OBJ";
	_Balrope = _obs select 5;
	_para = _obs select 1;
	_para2 = _obs select 1;
	_link = _obs select 4;
	_Scargo2 = (_this select 0);
	[_Scargo2,"P"] call SKM_UpdateState;
	deleteVehicle _para2;
	deleteVehicle _link;
	ropeCut[ropes _para select 0, ropeLength(ropes _para select 0)];
	detach _Scargo2;
	_Scargo2 switchMove "";
};
SKM_Release = {
	_obs = (_this select 0) getVariable "SKM_OBJ";
	_catcher = _obs select 6;
	detach (_this select 0);
	_catcher setVariable ["SKM_Catcher",1,true];
	[(_this select 0),"D"] call SKM_UpdateState;
};
While {true} do {
null = [] call SKM_Init;
sleep 15;
}