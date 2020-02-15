(*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.

Copyright (c) Alexey Torgashin
*)
unit proc_sidepanels;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Controls, ExtCtrls, Buttons, Forms,
  ATButtons,
  ATFlatToolbar,
  ATPanelSimple;

type
  TAppSideId = (
    cSideLeft,
    cSideBottom
    );

type
  { TAppSidePanel }

  TAppSidePanel = class
    ItemCaption: string;
    ItemControl: TCustomControl;
    ItemModule: string;
    ItemMethod: string;
    ItemOnShow: TNotifyEvent;
    procedure InitControl(const ACaption: string; AControl: TCustomControl;
      AParent: TWinControl);
  end;

type
  { TAppPanelHost }

  TAppPanelHost = class
  public
    ParentPanel: TATPanelSimple;
    Toolbar: TATFlatToolbar;
    Panels: TFPList;
    Splitter: TSplitter;
    LastActivePanel: string;
    DefaultPanel: string;
    FormFloat: TForm;
    constructor Create;
    destructor Destroy; override;
    function IsVisible: boolean;
    function IsFloating: boolean;
    function CaptionToPanelIndex(const ACaption: string): integer;
    function CaptionToTabIndex(const ACaption: string): integer;
    function CaptionToControlHandle(const ACaption: string): PtrInt;
    function AddTab(const ACaption: string; AImageIndex: integer; AHandle: PtrInt; AOnClick: TNotifyEvent): boolean;
    function AddTabEmpty(const ACaption: string; AImageIndex: integer; const AModule, AMethod: string; AOnClick: TNotifyEvent): boolean;
    function RemoveTab(const ACaption: string): boolean;
    procedure UpdateButtons;
  end;

var
  AppPanels: array[TAppSideId] of TAppPanelHost;

implementation

{ TAppSidePanel }

procedure TAppSidePanel.InitControl(const ACaption: string; AControl: TCustomControl; AParent: TWinControl);
begin
  ItemCaption:= ACaption;
  ItemControl:= AControl;
  ItemModule:= '';
  ItemMethod:= '';

  AControl.BorderStyle:= bsNone;
  AControl.Parent:= AParent;
  AControl.Align:= alClient;
end;

{ TAppPanelHost }

constructor TAppPanelHost.Create;
begin
  inherited Create;
  Panels:= TFPList.Create;
end;

destructor TAppPanelHost.Destroy;
begin
  Panels.Clear;
  FreeAndNil(Panels);
  inherited Destroy;
end;

function TAppPanelHost.IsVisible: boolean;
begin
  if IsFloating then
    Result:= FormFloat.Visible
  else
    Result:= ParentPanel.Visible;
end;

function TAppPanelHost.IsFloating: boolean;
begin
  Result:= Assigned(FormFloat) and (ParentPanel.Parent=FormFloat);
end;

function TAppPanelHost.CaptionToPanelIndex(const ACaption: string): integer;
var
  i: integer;
begin
  Result:= -1;
  for i:= 0 to Panels.Count-1 do
    with TAppSidePanel(Panels[i]) do
      if ItemCaption=ACaption then
        exit(i);
end;

function TAppPanelHost.CaptionToTabIndex(const ACaption: string): integer;
var
  i: integer;
begin
  Result:= -1;
  for i:= 0 to Toolbar.ButtonCount-1 do
    if SameText(Toolbar.Buttons[i].Caption, ACaption) then
      Exit(i);
end;

function TAppPanelHost.CaptionToControlHandle(const ACaption: string): PtrInt;
var
  Num: integer;
begin
  Result:= 0;
  Num:= CaptionToPanelIndex(ACaption);
  if Num<0 then exit;

  with TAppSidePanel(Panels[Num]) do
    if Assigned(ItemControl) then
      Result:= PtrInt(ItemControl);
end;

function TAppPanelHost.AddTab(const ACaption: string; AImageIndex: integer;
  AHandle: PtrInt; AOnClick: TNotifyEvent): boolean;
var
  Panel: TAppSidePanel;
  Num: integer;
  bExist: boolean;
begin
  Num:= CaptionToPanelIndex(ACaption);
  bExist:= Num>=0;

  if bExist then
    Panel:= TAppSidePanel(Panels[Num])
  else
  begin
    Panel:= TAppSidePanel.Create;
    Panels.Add(Panel);
  end;

  if AHandle<>0 then
    Panel.InitControl(ACaption, TCustomForm(AHandle), ParentPanel);

  if not bExist then
  begin
    Toolbar.AddButton(AImageIndex, AOnClick, ACaption, ACaption, '', false);
    Toolbar.UpdateControls;
  end;

  Result:= true;
end;

function TAppPanelHost.AddTabEmpty(const ACaption: string;
  AImageIndex: integer; const AModule, AMethod: string; AOnClick: TNotifyEvent): boolean;
var
  Panel: TAppSidePanel;
begin
  if CaptionToPanelIndex(ACaption)>=0 then exit(false);

  Panel:= TAppSidePanel.Create;
  Panel.ItemCaption:= ACaption;
  Panel.ItemControl:= nil;
  Panel.ItemModule:= AModule;
  Panel.ItemMethod:= AMethod;
  Panels.Add(Panel);

  //save module/method to Btn.DataString
  Toolbar.AddButton(AImageIndex, AOnClick, ACaption, ACaption,
    AModule+'.'+AMethod,
    false);
  Toolbar.UpdateControls;

  Result:= true;
end;

function TAppPanelHost.RemoveTab(const ACaption: string): boolean;
var
  Num, i: integer;
begin
  Num:= CaptionToTabIndex(ACaption);
  Result:= Num>=0;
  if Result then
  begin
    Toolbar.Buttons[Num].Free;
    Toolbar.UpdateControls;

    //hard to remove item, so hide it by "?"
    for i:= 0 to Panels.Count-1 do
      with TAppSidePanel(Panels[i]) do
        if ItemCaption=ACaption then
        begin
          ItemCaption:= '?';
          Break;
        end;
  end;
end;

procedure TAppPanelHost.UpdateButtons;
var
  Btn: TATButton;
  bVis: boolean;
  i: integer;
begin
  bVis:= IsVisible;
  for i:= 0 to Toolbar.ButtonCount-1 do
  begin
    Btn:= Toolbar.Buttons[i];
    Btn.Checked:= bVis and SameText(Btn.Caption, LastActivePanel);
  end;
end;


var
  Side: TAppSideId;

initialization

  for Side in TAppSideId do
    AppPanels[Side]:= TAppPanelHost.Create;

finalization

  for Side in TAppSideId do
    FreeAndNil(AppPanels[Side]);

end.
