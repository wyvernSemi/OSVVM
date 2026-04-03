--
--  File Name:         DynamicArrayGenericPkg.vhd
--  Design Unit Name:  DynamicArrayGenericPkg
--  Revision:          STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis          SynthWorks
--
--
--  Package Defines
--      Data structure for name. 
--
--  Developed for:
--        SynthWorks Design Inc.
--        VHDL Training Classes
--        11898 SW 128th Ave.  Tigard, Or  97223
--        http://www.SynthWorks.com
--
--  Revision History:
--    Version    Description
--    2026.05    Initial revision.  
--
--
--  This file is part of OSVVM.
--  
--  Copyright (c) 2026 by SynthWorks Design Inc.  
--  
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--  
--      https://www.apache.org/licenses/LICENSE-2.0
--  
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
--  

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;
use ieee.math_real.all ;
use std.textio.all ;

use work.IfElsePkg.all ;
use work.OsvvmScriptSettingsPkg.all ;
use work.OsvvmSettingsPkg.all ;
use work.TextUtilPkg.all ;
use work.ResolutionPkg.all ;
use work.TranscriptPkg.all ;
use work.AlertLogPkg.all ;
use work.NameStorePkg.all ;
use work.LanguageSupport2019Pkg.all ;
use work.IdFifoPTypePkg.all ; 

package DynamicArrayGenericPkg is 
  generic (type ArrayType is array (type is range <>) of type is private ) ;

  subtype ElementType is ArrayType'element ; 
  subtype IndexType is ArrayType'index ; 

  type InternalArrayType is array (integer range <>) of ElementType ; 
  constant FIRST_INDEX   : integer := 0 ; 

  type DynamicArrayIDType is record
    IdNum     : integer_max ;
    CopyNum   : integer_max ; 
  end record DynamicArrayIDType ; 

  constant EMPTY_DYNAMIC_ARRAY_ID : DynamicArrayIDType := (IdNum => 0, CopyNum => 0) ;

  type DynamicArrayIDArrayType is array (integer range <>) of DynamicArrayIDType ;  
  
  ------------------------------------------------------------
  impure function NewID (
    Name                : String ;
    Size                : natural ; 
    ParentID            : AlertLogIDType          := OSVVM_COVERAGE_ALERTLOG_ID ;
    ReportMode          : AlertLogReportModeType  := ENABLED ;
    Search              : NameSearchType          := PRIVATE_NAME ;
    PrintParent         : AlertLogPrintParentType := PRINT_NAME_AND_PARENT
  ) return DynamicArrayIDType ;

--  impure function NewID (
--    Name                : String ;
----    Size                : natural ;  -- Size is 0
--    ParentID            : AlertLogIDType          := OSVVM_COVERAGE_ALERTLOG_ID ;
--    ReportMode          : AlertLogReportModeType  := ENABLED ;
--    Search              : NameSearchType          := PRIVATE_NAME ;
--    PrintParent         : AlertLogPrintParentType := PRINT_NAME_AND_PARENT
--  ) return DynamicArrayIDType ;
  
  impure function CopyID ( SiblingID : DynamicArrayIDType ) return DynamicArrayIDType ;

  ------------------------------------------------------------
  -- Append
  --   Add element(s) to the end of the list
  --   Same as Push / Push Back
  procedure Append (
    ID        : DynamicArrayIDType ; 
    iValue    : ElementType
  ) ;

  procedure Append (
    ID        : DynamicArrayIDType ; 
    iValue    : ArrayType
  ) ;

  ------------------------------------------------------------
  impure function Get  (
    ID        : DynamicArrayIDType ; 
    Index     : integer 
  ) return ElementType ;

  impure function Get  (
    ID        : DynamicArrayIDType ; 
    Index     : integer ;
    NumValues : integer 
  ) return ArrayType ;

  ------------------------------------------------------------
  procedure Set (
    ID       : DynamicArrayIDType ; 
    Index    : integer ;
    iValue   : ElementType 
  ) ;
  
  procedure Set (
    ID       : DynamicArrayIDType ; 
    Index    : integer ;
    iValue   : ArrayType 
  ) ;
  
  ------------------------------------------------------------
  procedure SetIndex   (ID : DynamicArrayIDType ; Index : integer := FIRST_INDEX) ;

  ------------------------------------------------------------
  -- GetNext
  --   Get value at Index and Increment Index
  --
  impure function GetNext (
    ID        : DynamicArrayIDType 
  ) return ElementType ; 

  impure function GetNext (
    ID        : DynamicArrayIDType ;
    NumValues : natural 
  ) return ArrayType ; 

  ------------------------------------------------------------
  impure function IsEmpty       (ID : DynamicArrayIDType) return boolean ;  -- Does ID have storage
  impure function Deallocate    (ID : DynamicArrayIDType) return DynamicArrayIDType; 
  impure function IsInitialized (ID : DynamicArrayIDType) return boolean ; -- ID Valid

  ------------------------------------------------------------
  impure function GetSize      (ID : DynamicArrayIDType) return integer ;
  impure function GetCapacity  (ID : DynamicArrayIDType) return integer ;
  procedure MakeEmpty          (ID : DynamicArrayIDType) ;

end package DynamicArrayGenericPkg ;

--- ///////////////////////////////////////////////////////////////////////////
--- ///////////////////////////////////////////////////////////////////////////
--- ///////////////////////////////////////////////////////////////////////////

package body DynamicArrayGenericPkg is
  constant ITERATOR_LENGTH_INIT : integer := 3 ; 
  constant ITERATOR_LENGTH_GROW : integer := 3 ;
  constant INITIAL_ARRAY_SIZE     : integer := 16 ;
--!!ArrayType if use IndexType in array, then this becomes IndexType'left

  type DynamicArrayPType is protected
    ------------------------------------------------------------
    impure function NewID (
      Name                : String ;
      Size                : natural ; 
      ParentID            : AlertLogIDType ;
      ReportMode          : AlertLogReportModeType  ;  -- These use the ParentAlertID rather than creating their own AlertLogID
      Search              : NameSearchType ;           -- These are always private and cloned to hand off
      PrintParent         : AlertLogPrintParentType 
    ) return DynamicArrayIDType ;

    impure function CopyID ( SiblingID : DynamicArrayIDType ) return DynamicArrayIDType ;

    ------------------------------------------------------------
    -- Append
    --   Add element(s) to the end of the list
    --   Same as Push / Push Back
    procedure Append (
      ID        : DynamicArrayIDType ; 
      iValue    : ElementType
    ) ;

    procedure Append (
      ID        : DynamicArrayIDType ; 
      iValue    : InternalArrayType
    ) ;

    ------------------------------------------------------------
    -- GetNext
    --   Remove element(s) 
    --   Same as Pop / Pop Front
    impure function GetNext (
      ID        : DynamicArrayIDType 
    ) return ElementType ; 

    impure function GetNext (
      ID        : DynamicArrayIDType ;
      NumValues : natural 
    ) return InternalArrayType ; 

    ------------------------------------------------------------
    impure function Get  (
      ID        : DynamicArrayIDType ; 
      Index     : integer 
    ) return ElementType ;

    impure function Get  (
      ID        : DynamicArrayIDType ; 
      Index     : integer ;
      NumValues : integer 
    ) return InternalArrayType ;

    ------------------------------------------------------------
    procedure Set (
      ID       : DynamicArrayIDType ; 
      Index    : integer ;
      iValue   : ElementType 
    ) ;
    
    procedure Set (
      ID       : DynamicArrayIDType ; 
      Index    : integer ;
      iValue   : InternalArrayType 
    ) ;
    
    ------------------------------------------------------------
    impure function IsEmpty       (ID : DynamicArrayIDType) return boolean ;  -- Does ID have storage
    impure function Deallocate    (ID : DynamicArrayIDType) return DynamicArrayIDType ; 
    impure function IsInitialized (ID : DynamicArrayIDType) return boolean ; -- ID Valid

    ------------------------------------------------------------
    impure function GetSize     (ID : DynamicArrayIDType) return integer ;
    impure function GetCapacity (ID : DynamicArrayIDType) return integer ;
    procedure MakeEmpty         (ID : DynamicArrayIDType) ;
    procedure SetIndex  (ID : DynamicArrayIDType ; Index : integer := FIRST_INDEX) ;

  end protected DynamicArrayPType ;

  type DynamicArrayPType is protected body

    type IteratorType is record
      HeadIndex   : integer ; 
      InUse       : boolean ; 
    end record IteratorType ; 

    type IteratorArrayType is array (natural range <>) of IteratorType ;
    type IteratorArrayPtrType is access IteratorArrayType ; 

    type ArrayPtrType is access InternalArrayType ; 

    -- type IntegerVectorPtrType is access integer_vector ; 

    type DynamicArrayRecType is record
      ArrayPtr       : ArrayPtrType ; 
--      HeadIndexPtr   : IntegerVectorPtrType ; 
      IteratorPtr    : IteratorArrayPtrType ; 
      TailIndex      : integer ; 
      Capacity       : integer ; 
      MaxCopyNum     : integer ; 
      ActiveClones   : integer ; 
      AlertLogID     : AlertLogIDType ; 
    end record DynamicArrayRecType ; 
    
    type  DynamicArrayRecPtrType is access DynamicArrayRecType ;
    type  SingletonArrayType     is array (integer range <>) of DynamicArrayRecPtrType ; 
    type  SingletonArrayPtrType  is access SingletonArrayType ;

    variable SingletonArrayPtr   : SingletonArrayPtrType ;   
    variable NumItems            : integer := 0 ; 
    variable MaxItems            : integer := 0 ;
    constant MIN_NUM_ITEMS       : integer := 32 ; -- Min amount to resize array

    variable IdFifo : IdFifoPType ; 

--!!    ------------------------------------------------------------
--!!    -- Package Local
--!!    function NormalizeArraySize( NewNumItems, MinNumItems : integer ) return integer is
--!!    ------------------------------------------------------------
--!!      variable NormNumItems : integer ;
--!!      variable ModNumItems  : integer ;
--!!    begin
--!!      NormNumItems := NewNumItems ; 
--!!      ModNumItems  := NewNumItems mod MinNumItems ; 
--!!      if ModNumItems > 0 then 
--!!        NormNumItems := NormNumItems + (MinNumItems - ModNumItems) ; 
--!!      end if ; 
--!!      return NormNumItems ; 
--!!    end function NormalizeArraySize ;
--!!
--!!    ------------------------------------------------------------
--!!    -- Package Local
--!!    procedure GrowNumberItems (
--!!    ------------------------------------------------------------
--!!      variable ItemArrayPtr     : InOut SingletonArrayPtrType ;
--!!      variable NumItems         : InOut integer ;
--!!      constant GrowAmount       : in integer ;
--!!      constant MinNumItems      : in integer 
--!!    ) is
--!!      variable oldItemArrayPtr  : SingletonArrayPtrType ;
--!!      variable NewNumItems  : integer ;
--!!      variable NewSize      : integer ;
--!!    begin
--!!      NewNumItems := NumItems + GrowAmount ; 
--!!      NewSize     := NormalizeArraySize(NewNumItems, MinNumItems) ;
--!!      if ItemArrayPtr = NULL then
--!!        ItemArrayPtr := new SingletonArrayType(1 to NewSize) ;
--!!      elsif NewNumItems > ItemArrayPtr'length then
--!!        oldItemArrayPtr := ItemArrayPtr ;
--!!        ItemArrayPtr := new SingletonArrayType(1 to NewSize) ;
--!!        ItemArrayPtr.all(1 to NumItems) := oldItemArrayPtr.all(1 to NumItems) ;
--!!        deallocate(oldItemArrayPtr) ;
--!!      end if ;
--!!      NumItems := NewNumItems ; 
--!!    end procedure GrowNumberItems ;

    ------------------------------------------------------------
    impure function IsInitialized (ID : DynamicArrayIDType) return boolean is
    ------------------------------------------------------------
      constant IdNum : integer := ID.IdNum ; 
    begin
      if IdNum >= 1 and IdNum <= NumItems then 
        if SingletonArrayPtr(IdNum) /= NULL then
          if SingletonArrayPtr(IdNum).IteratorPtr /= NULL and SingletonArrayPtr(IdNum).ArrayPtr /= NULL then
            if SingletonArrayPtr(IdNum).IteratorPtr(ID.CopyNum).InUse then
              return TRUE ;  -- Initialized
            end if ; 
          end if ; 
        end if ; 
      end if ; 
      return FALSE ; -- Not Initialized
    end function IsInitialized ;

    ------------------------------------------------------------
    --  Package Local  
    impure function CopyNotInUse(ID : DynamicArrayIDType ; Name : string) return boolean is
    ------------------------------------------------------------
      constant IdNum : integer := ID.IdNum ; 
    begin
      if IdNum >= 1 and IdNum <= MaxItems then 
        if SingletonArrayPtr(IdNum) /= NULL then
          if SingletonArrayPtr(IdNum).IteratorPtr /= NULL and SingletonArrayPtr(IdNum).ArrayPtr /= NULL then
            if SingletonArrayPtr(IdNum).IteratorPtr(ID.CopyNum).InUse then
              return FALSE ;  -- In USE
            end if ; 
          end if ; 
        end if ; 
      end if ; 
      Alert("DynamicArray: " & Name & ", IdNum: " & to_string(ID.IdNum) & "  CopyNum: " & to_string(ID.CopyNum), FAILURE) ;
      return TRUE ; -- Not In USE
    end function CopyNotInUse ; 

    ------------------------------------------------------------
    -- Package Local
    impure function NextIdNumber return integer is
    ------------------------------------------------------------
      variable oldItemArrayPtr  : SingletonArrayPtrType ;
    begin
      if not IdFifo.IsEmpty then 
        NumItems := NumItems + 1 ;
        return IdFifo.Pop ; 
      elsif SingletonArrayPtr = NULL then 
        MaxItems := MIN_NUM_ITEMS ; 
        SingletonArrayPtr := new SingletonArrayType(1 to MaxItems) ;
        NumItems := 1 ;
      else 
        AlertIfNotEqual(NumItems, SingletonArrayPtr'length, "NextIdNumber: NumItems /= SingletonArrayPtr'length") ;
        MaxItems := MaxItems + 32 ; 
        OldItemArrayPtr := SingletonArrayPtr ;
        SingletonArrayPtr := new SingletonArrayType(1 to MaxItems) ;
        SingletonArrayPtr.all(1 to NumItems) := oldItemArrayPtr.all(1 to NumItems) ;
        deallocate(oldItemArrayPtr) ;
        NumItems := NumItems + 1 ; 
      end if ; 
      for i in NumItems + 1 to MaxItems loop 
        IdFifo.push(i) ;
      end loop ; 
      return NumItems ; 
    end function NextIdNumber ;

    ------------------------------------------------------------
    impure function NewID (
    ------------------------------------------------------------
      Name                : String ;
      Size                : natural ; 
      ParentID            : AlertLogIDType ;
      ReportMode          : AlertLogReportModeType  ;  -- These use the ParentAlertID rather than creating their own AlertLogID
      Search              : NameSearchType ;           -- These are always private and cloned to hand off
      PrintParent         : AlertLogPrintParentType 
    ) return DynamicArrayIDType is
      variable ID           : DynamicArrayIDType ; 
      variable ResolvedSize : integer ; 
      variable IdNum      : integer ;
    begin
      ResolvedSize := Maximum(Size, INITIAL_ARRAY_SIZE) ;
      -- GrowNumberItems(SingletonArrayPtr, NumItems, 1, MIN_NUM_ITEMS) ;
      IdNum := NextIdNumber ; 
      SingletonArrayPtr(IdNum) := new DynamicArrayRecType ;
--      SingletonArrayPtr(IdNum).HeadIndexPtr := new integer_vector'(1 to ITERATOR_LENGTH_INIT => FIRST_INDEX) ; 
      SingletonArrayPtr(IdNum).IteratorPtr := new IteratorArrayType'(1 to ITERATOR_LENGTH_INIT => (FIRST_INDEX, FALSE)) ; 
      SingletonArrayPtr(IdNum).IteratorPtr(1).InUse := TRUE ; 
      SingletonArrayPtr(IdNum).TailIndex    := FIRST_INDEX ; 
      SingletonArrayPtr(IdNum).ActiveClones := 1 ; 
      SingletonArrayPtr(IdNum).MaxCopyNum  := 1 ; 
      SingletonArrayPtr(IdNum).AlertLogID   := ParentID ; 
      SingletonArrayPtr(IdNum).Capacity     := ResolvedSize ; 
      SingletonArrayPtr(IdNum).ArrayPtr     := new InternalArrayType(FIRST_INDEX to FIRST_INDEX - 1 + ResolvedSize ) ; 
      ID.IdNum      := IdNum ; 
      ID.CopyNum   := 1 ; 
      return ID ; 
    end function NewID ;

    ------------------------------------------------------------
    impure function CopyID ( SiblingID : DynamicArrayIDType ) return DynamicArrayIDType is
    ------------------------------------------------------------
      variable ID : DynamicArrayIDType ; 
      variable IdNum, vCopyNum : integer ; 
      variable OrigIteratorLength : integer ; 
      variable OldIteratorPtr, IteratorPtr : IteratorArrayPtrType ; 
    begin
      if CopyNotInUse(SiblingID, "CopyID") then
        return EMPTY_DYNAMIC_ARRAY_ID ; 
      end if ; 
      IdNum      := SiblingID.IdNum ; 
      ID.IdNum   := IdNum ; 
      vCopyNum   := SingletonArrayPtr(IdNum).MaxCopyNum + 1 ; 
      ID.CopyNum := vCopyNum ; 
      SingletonArrayPtr(IdNum).MaxCopyNum  := vCopyNum ; 
      SingletonArrayPtr(IdNum).ActiveClones := SingletonArrayPtr(IdNum).ActiveClones + 1 ; 
      OrigIteratorLength := SingletonArrayPtr(IdNum).IteratorPtr'length ;
      if vCopyNum > OrigIteratorLength then
        OldIteratorPtr := SingletonArrayPtr(IdNum).IteratorPtr ;
        -- IteratorPtr := new integer_vector'(1 to OrigIteratorLength + ITERATOR_LENGTH_GROW => 1) ;
        IteratorPtr := new IteratorArrayType'(1 to OrigIteratorLength + ITERATOR_LENGTH_GROW => (FIRST_INDEX, FALSE)) ; 
        IteratorPtr.all(1 to OrigIteratorLength) := OldIteratorPtr.all(1 to OrigIteratorLength) ;
        deallocate(OldIteratorPtr) ;
        SingletonArrayPtr(IdNum).IteratorPtr := IteratorPtr ; 
      end if ; 
      SingletonArrayPtr(IdNum).IteratorPtr(vCopyNum).InUse := TRUE ; 
      return ID ; 
    end function CopyID ; 

    ------------------------------------------------------------
    -- Package Local
    procedure ResizeArrayPtr (
    ------------------------------------------------------------
      IdNum       : Integer ; 
      EndingIndex : Integer 
    ) is
      variable OldArrayPtr        : ArrayPtrType ;
      variable OldSize, NewSize   : integer ;
    begin
      OldSize := SingletonArrayPtr(IdNum).Capacity ;
      NewSize := OldSize ; 
      while NewSize <= EndingIndex loop
        NewSize := NewSize * 2 ; 
      end loop ; 

      OldArrayPtr := SingletonArrayPtr(IdNum).ArrayPtr ; 
      SingletonArrayPtr(IdNum).ArrayPtr := new InternalArrayType(FIRST_INDEX to FIRST_INDEX - 1 + NewSize) ;
      SingletonArrayPtr(IdNum).Capacity := NewSize ; 
      SingletonArrayPtr(IdNum).ArrayPtr.all(FIRST_INDEX to FIRST_INDEX - 1 + OldSize) := OldArrayPtr.all(FIRST_INDEX to FIRST_INDEX - 1 + OldSize) ;
      deallocate(OldArrayPtr) ;
    end procedure ResizeArrayPtr ;

    ------------------------------------------------------------
    -- Append
    --   Add element(s) to the end of the list
    ------------------------------------------------------------
    procedure Append (
      ID        : DynamicArrayIDType ; 
      iValue    : ElementType
    ) is
      variable EndingIndex : natural ;
      variable IdNum : integer ;
    begin
      if CopyNotInUse(ID, "Append") then
        return ; 
      end if ; 
      IdNum := ID.IdNum ; 
      EndingIndex := SingletonArrayPtr(IdNum).TailIndex ; 
      if SingletonArrayPtr(IdNum).Capacity <= EndingIndex then
        ResizeArrayPtr(IdNum, EndingIndex) ; 
      end if ; 
      SingletonArrayPtr(IdNum).TailIndex := EndingIndex + 1 ; 
      SingletonArrayPtr(IdNum).ArrayPtr(EndingIndex) := iValue ; 
    end procedure Append ;

    ------------------------------------------------------------
    procedure Append (
    ------------------------------------------------------------
      ID        : DynamicArrayIDType ; 
      iValue    : InternalArrayType
    ) is
      variable StartingIndex : natural ;
      variable NewTailIndex  : natural ;
      variable EndingIndex   : natural ;
      constant ArraySize     : natural := iValue'length ; 
      variable IdNum        : integer ;
    begin
      if CopyNotInUse(ID, "Append") then
        return ; 
      end if ; 
      IdNum := ID.IdNum ; 
      StartingIndex := SingletonArrayPtr(IdNum).TailIndex ; 
      NewTailIndex  := SingletonArrayPtr(IdNum).TailIndex + ArraySize ; 
      EndingIndex   := NewTailIndex - 1 ; 
      if SingletonArrayPtr(IdNum).Capacity <= EndingIndex then
        ResizeArrayPtr(IdNum, EndingIndex) ; 
      end if ; 
      SingletonArrayPtr(IdNum).TailIndex := NewTailIndex ; 
      SingletonArrayPtr(IdNum).ArrayPtr(StartingIndex to EndingIndex) := iValue ; 
    end procedure Append ;

    ------------------------------------------------------------
    -- Package Local
    impure function CheckIndex  (
    ------------------------------------------------------------
      ID        : DynamicArrayIDType ; 
      Index    : integer 
    ) return boolean is
    begin
--      return Index >= SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).HeadIndex and Index < SingletonArrayPtr(ID.IdNum).TailIndex ;
      return Index >= FIRST_INDEX and Index < SingletonArrayPtr(ID.IdNum).TailIndex ;
    end function CheckIndex ; 

    ------------------------------------------------------------
    -- Package Local
    impure function CheckIndex  (
    ------------------------------------------------------------
      ID                         : DynamicArrayIDType ; 
      StartingIndex, EndingIndex : integer 
    ) return boolean is
    begin
--      return StartingIndex >= SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).HeadIndex and EndingIndex < SingletonArrayPtr(ID.IdNum).TailIndex ;
      return StartingIndex >= FIRST_INDEX and EndingIndex < SingletonArrayPtr(ID.IdNum).TailIndex ;
    end function CheckIndex ; 

    ------------------------------------------------------------
    impure function Get  (
    ------------------------------------------------------------
      ID        : DynamicArrayIDType ; 
      Index     : integer 
    ) return ElementType is
      variable Result : ElementType ;
      variable StartingIndex : integer ; 
    begin
      if CopyNotInUse(ID, "Get") then
        return Result ; 
      end if ; 
--      StartingIndex := SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).HeadIndex + Index ; 
      StartingIndex := FIRST_INDEX + Index ; 
      if CheckIndex(ID, StartingIndex) then 
        return SingletonArrayPtr(ID.IdNum).ArrayPtr(StartingIndex) ;  
      else
        Alert(SingletonArrayPtr(ID.IdNum).AlertLogID, "", FAILURE)  ; 
        return Result ;
      end if ; 
    end function Get ;

    ------------------------------------------------------------
    impure function Get  (
    ------------------------------------------------------------
      ID        : DynamicArrayIDType ; 
      Index     : integer ;
      NumValues : integer 
    ) return InternalArrayType is
      variable Result : InternalArrayType(1 to NumValues) ;
      variable StartingIndex, EndingIndex : integer ;
    begin
      if CopyNotInUse(ID, "Get") then
        return Result ; 
      end if ; 
  --    StartingIndex := SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).HeadIndex + Index ; 
      StartingIndex := FIRST_INDEX + Index ; 
      EndingIndex   := StartingIndex + NumValues - 1 ; 
      if CheckIndex(ID, StartingIndex, EndingIndex) then 
        return SingletonArrayPtr(ID.IdNum).ArrayPtr(StartingIndex to EndingIndex) ;
      else
        Alert(SingletonArrayPtr(ID.IdNum).AlertLogID, "", FAILURE)  ; 
        return Result ;  
      end if ; 
    end function Get ;

    ------------------------------------------------------------
    procedure Set (
    ------------------------------------------------------------
      ID       : DynamicArrayIDType ; 
      Index    : integer ;
      iValue   : ElementType 
    ) is
      variable StartingIndex : integer ; 
    begin
      if CopyNotInUse(ID, "Set") then
        return ; 
      end if ; 
--      StartingIndex := SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).HeadIndex + Index ; 
      StartingIndex := FIRST_INDEX + Index ; 
      if CheckIndex(ID, StartingIndex) then 
        SingletonArrayPtr(ID.IdNum).ArrayPtr(StartingIndex) := iValue ;
      else
        Alert(SingletonArrayPtr(ID.IdNum).AlertLogID, "", FAILURE)  ; 
      end if ; 
    end procedure Set ;

    ------------------------------------------------------------
    procedure Set (
    ------------------------------------------------------------
      ID       : DynamicArrayIDType ; 
      Index    : integer ;
      iValue   : InternalArrayType 
    ) is
      variable StartingIndex, EndingIndex : integer ; 
    begin
      if CopyNotInUse(ID, "Set") then
        return ; 
      end if ; 
--      StartingIndex := SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).HeadIndex + Index ; 
      StartingIndex := FIRST_INDEX + Index ; 
      EndingIndex   := StartingIndex + iValue'length - 1 ; 
      if CheckIndex(ID, StartingIndex, EndingIndex) then 
        SingletonArrayPtr(ID.IdNum).ArrayPtr(StartingIndex to EndingIndex) := iValue ;
      else
        Alert(SingletonArrayPtr(ID.IdNum).AlertLogID, "", FAILURE)  ; 
      end if ; 
    end procedure Set ;

    ------------------------------------------------------------
    impure function IsEmpty   (ID : DynamicArrayIDType) return boolean is
    ------------------------------------------------------------
    begin
      if CopyNotInUse(ID, "IsEmpty") then
        return TRUE ; 
      end if ; 
      return SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).HeadIndex >= SingletonArrayPtr(ID.IdNum).TailIndex ;
    end function IsEmpty ; 

    ------------------------------------------------------------
    impure function GetIndex (ID : DynamicArrayIDType) return integer is
    ------------------------------------------------------------
    begin
      if CopyNotInUse(ID, "GetIndex") then
        return -1 ; 
      end if ; 
      return SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).HeadIndex ; 
    end function GetIndex ; 

    ------------------------------------------------------------
    impure function GetFirstIndex (ID : DynamicArrayIDType) return integer is
    ------------------------------------------------------------
    begin
      if CopyNotInUse(ID, "GetFirstIndex") then
        return -1 ; 
      end if ; 
      return FIRST_INDEX ; 
    end function GetFirstIndex ; 

    ------------------------------------------------------------
    impure function GetLastIndex (ID : DynamicArrayIDType; NumValues : natural := 0) return integer is
    -- With NumValues = 0, LastIndex is a reference to the next empty index
    ------------------------------------------------------------
    begin
      if CopyNotInUse(ID, "GetLastIndex") then
        return FALSE ; 
      end if ; 
      return SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).TailIndex - NumValues ; 
    end function GetLastIndex ; 

    ------------------------------------------------------------
    impure function IndexNext (ID : DynamicArrayIDType; NumValues : integer := 1) return integer is
    ------------------------------------------------------------
      variable CurIndex : integer ; 
    begin
      if CopyNotInUse(ID, "GetNextIndex") then
        return FALSE ; 
      end if ; 
      CurIndex := SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).HeadIndex ; 
      SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).HeadIndex := CurIndex + NumValues ; 
      return CurIndex ; 
    end function IndexNext ; 

    ------------------------------------------------------------
    impure function HasNext   (ID : DynamicArrayIDType; NumValues : integer := 1) return boolean is
    ------------------------------------------------------------
    begin
      if CopyNotInUse(ID, "HasNext") then
        return FALSE ; 
      end if ; 
      return SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).HeadIndex + NumValues <= SingletonArrayPtr(ID.IdNum).TailIndex ;
    end function HasNext ; 

    ------------------------------------------------------------
    -- GetNext
    --   Get element(s) 
    ------------------------------------------------------------
    impure function GetNext (
      ID        : DynamicArrayIDType 
    ) return ElementType is
      variable StartingIndex : natural ;
      variable Result : ElementType ;
--      variable IdNum        : integer ;
    begin
      if CopyNotInUse(ID, "GetNext") then
        return Result ; 
      end if ; 
      StartingIndex := SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).HeadIndex ;
      SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).HeadIndex := StartingIndex + 1 ;
      return Get(ID, StartingIndex) ;
--      IdNum := ID.IdNum ; 
--      StartingIndex := SingletonArrayPtr(IdNum).IteratorPtr(ID.CopyNum).HeadIndex ;
--      if StartingIndex < SingletonArrayPtr(IdNum).TailIndex then 
--        Result := SingletonArrayPtr(IdNum).ArrayPtr(StartingIndex) ;
--        SingletonArrayPtr(IdNum).IteratorPtr(ID.CopyNum).HeadIndex:= StartingIndex + 1 ; 
--        return Result ;
--      else
--        Alert(SingletonArrayPtr(IdNum).AlertLogID, "", FAILURE)  ; 
--        return Result ;  
--      end if ; 
    end function GetNext ;
 
    ------------------------------------------------------------
    impure function GetNext (
    ------------------------------------------------------------
      ID        : DynamicArrayIDType ;
      NumValues : natural 
    ) return InternalArrayType is
      variable StartingIndex : natural ;
      variable Result : InternalArrayType(1 to NumValues) ;
      -- variable NewHeadIndex  : natural ;
      -- variable EndingIndex   : natural ;
      -- variable IdNum        : integer ;
    begin
      if CopyNotInUse(ID, "GetNext") then
        return Result ; 
      end if ; 
      StartingIndex := SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).HeadIndex ;
      SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).HeadIndex := StartingIndex + Numvalues ;
      return Get(ID, StartingIndex, NumValues) ;

--      IdNum := ID.IdNum ; 
--      StartingIndex := SingletonArrayPtr(IdNum).IteratorPtr(ID.CopyNum).HeadIndex ;
--      NewHeadIndex  := StartingIndex + NumValues ; 
--      EndingIndex   := NewHeadIndex - 1 ; 
--      if EndingIndex >= SingletonArrayPtr(IdNum).TailIndex then 
--        Alert(SingletonArrayPtr(IdNum).AlertLogID, "", FAILURE)  ; 
--        return Result ;  
--      else
--        SingletonArrayPtr(IdNum).IteratorPtr(ID.CopyNum).HeadIndex:= NewHeadIndex ; 
--        Result := SingletonArrayPtr(IdNum).ArrayPtr(StartingIndex to EndingIndex) ;
--        return Result ;
--      end if ; 
    end function GetNext ;
 
    ------------------------------------------------------------
    -- SetNext
    --   Set element(s) 
    ------------------------------------------------------------
    impure function SetNext (
      ID        : DynamicArrayIDType 
    ) return ElementType is
      variable StartingIndex : natural ;
    begin
      if CopyNotInUse(ID, "SetNext") then
        return ; 
      end if ; 
      StartingIndex := SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).HeadIndex ;
      SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).HeadIndex := StartingIndex + 1 ;
      Set(ID, StartingIndex) ;
    end function SetNext ;
 
    ------------------------------------------------------------
    impure function SetNext (
    ------------------------------------------------------------
      ID        : DynamicArrayIDType ;
      NumValues : natural 
    ) return InternalArrayType is
      variable StartingIndex : natural ;
    begin
      if CopyNotInUse(ID, "SetNext") then
        return ; 
      end if ; 
      StartingIndex := SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).HeadIndex ;
      SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).HeadIndex := StartingIndex + Numvalues ;
      Set(ID, StartingIndex, NumValues) ;
    end function SetNext ;

    ------------------------------------------------------------
    impure function Deallocate(ID : DynamicArrayIDType) return DynamicArrayIDType is
    ------------------------------------------------------------
    begin
      if CopyNotInUse(ID, "Deallocate") then
        return EMPTY_DYNAMIC_ARRAY_ID ; 
      end if ; 
      SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).InUse := FALSE ; 
      SingletonArrayPtr(ID.IdNum).ActiveClones := SingletonArrayPtr(ID.IdNum).ActiveClones - 1 ; 
      if SingletonArrayPtr(ID.IdNum).ActiveClones <= 0 then
--!! Put IteratorPtr on a MemoryPool.
        deallocate(SingletonArrayPtr(ID.IdNum).IteratorPtr) ;
--!! Put ArrayPtr on a MemoryPool.
        deallocate(SingletonArrayPtr(ID.IdNum).ArrayPtr) ;
        IdFifo.push(ID.IdNum) ;
        NumItems := NumItems - 1 ; 
      end if ; 
      return EMPTY_DYNAMIC_ARRAY_ID ; 
    end function Deallocate ;

    ------------------------------------------------------------
    impure function GetSize (ID : DynamicArrayIDType) return integer is
    ------------------------------------------------------------
    begin
      if CopyNotInUse(ID, "GetSize") then
        return -1 ; 
      end if ; 
      return SingletonArrayPtr(ID.IdNum).TailIndex - 
             SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).HeadIndex ;
    end function GetSize ;

    ------------------------------------------------------------
    impure function GetCapacity (ID : DynamicArrayIDType) return integer is
    ------------------------------------------------------------
    begin
      if CopyNotInUse(ID, "GetCapacity") then
        return -1 ; 
      end if ; 
      return SingletonArrayPtr(ID.IdNum).Capacity ;
    end function GetCapacity ;

    ------------------------------------------------------------
    procedure MakeEmpty (ID : DynamicArrayIDType) is
    ------------------------------------------------------------
    begin
      if CopyNotInUse(ID, "GetCapacity") then
        return ; 
      end if ; 
      SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).HeadIndex := FIRST_INDEX ;
      SingletonArrayPtr(ID.IdNum).TailIndex := FIRST_INDEX ;
    end procedure MakeEmpty ;

    ------------------------------------------------------------
    procedure SetIndex (ID : DynamicArrayIDType ; Index : integer := FIRST_INDEX) is
    ------------------------------------------------------------
    begin
      if CopyNotInUse(ID, "SetIndex") then
        return ; 
      end if ; 
      SingletonArrayPtr(ID.IdNum).IteratorPtr(ID.CopyNum).HeadIndex := Index ;
    end procedure SetIndex ;

  end protected body DynamicArrayPType ;
  

-- /////////////////////////////////////////
-- /////////////////////////////////////////
-- Singleton Data Structure
-- /////////////////////////////////////////
-- /////////////////////////////////////////
  shared variable DynamicArrayStore : DynamicArrayPType ; 
  
  function reverseIAT (A : InternalArrayType) return InternalArrayType is
    variable RevA : InternalArrayType(A'reverse_range) ;
  begin
    for i in A'range loop 
      RevA(i) := A(i) ;
    end loop ; 
    return RevA ; 
  end function reverseIAT ; 

  function reverse (A : InternalArrayType) return ArrayType is
    constant LowIndex   : integer := integer(IndexType'low) ; 
    constant HighIndex  : integer := LowIndex + A'length - 1 ;
    variable Result : ArrayType(IndexType(LowIndex) to IndexType(HighIndex)) ;
    alias revA : InternalArrayType (HighIndex downto LowIndex) is A ; 
  begin
    for i in Result'range loop 
      Result(i) := RevA(integer(i)) ;
    end loop ; 
    return Result ; 
  end function reverse ; 

  function reverse (A : ArrayType) return InternalArrayType is
    constant LowIndex   : integer := integer(IndexType'low) ; 
    constant HighIndex  : integer := LowIndex + A'length - 1 ;
    variable Result : InternalArrayType(HighIndex downto LowIndex) ;
    alias revA : ArrayType (IndexType(LowIndex) to IndexType(HighIndex)) is A ; 
  begin
    for i in revA'range loop 
      Result(integer(i)) := RevA(i) ;
    end loop ; 
    return Result ; 
  end function reverse ; 

  ------------------------------------------------------------
  impure function NewID (
    Name                : String ;
    Size                : natural ; 
    ParentID            : AlertLogIDType          := OSVVM_COVERAGE_ALERTLOG_ID ;
    ReportMode          : AlertLogReportModeType  := ENABLED ;
    Search              : NameSearchType          := PRIVATE_NAME ;
    PrintParent         : AlertLogPrintParentType := PRINT_NAME_AND_PARENT
  ) return DynamicArrayIDType is
  begin
    return DynamicArrayStore.NewID(Name, Size, ParentID, ReportMode, Search, PrintParent) ;
  end function NewID ;

--  impure function NewID (
--    Name                : String ;
----    Size                : natural ;  -- Size is 0
--    ParentID            : AlertLogIDType          := OSVVM_COVERAGE_ALERTLOG_ID ;
--    ReportMode          : AlertLogReportModeType  := ENABLED ;
--    Search              : NameSearchType          := PRIVATE_NAME ;
--    PrintParent         : AlertLogPrintParentType := PRINT_NAME_AND_PARENT
--  ) return DynamicArrayIDType is
--  begin
--    return DynamicArrayStore.NewID(Name, 0, ParentID, ReportMode, Search, PrintParent) ;
--  end function NewID ;
  
  impure function CopyID ( SiblingID : DynamicArrayIDType ) return DynamicArrayIDType is
  begin
    return DynamicArrayStore.CopyID(SiblingID) ;
  end function CopyID ;

  ------------------------------------------------------------
  -- Append
  --   Add element(s) to the end of the list
  --   Same as Push / Push Back
  procedure Append (
    ID        : DynamicArrayIDType ; 
    iValue    : ElementType
  ) is
  begin
    DynamicArrayStore.Append(ID, iValue) ;
  end procedure Append ;

  procedure Append (
    ID        : DynamicArrayIDType ; 
    iValue    : ArrayType
  ) is
  begin
--    DynamicArrayStore.Append(ID, ReverseIAT(InternalArrayType(iValue))) ;
    DynamicArrayStore.Append(ID, reverse(iValue)) ;
  end procedure Append ;

  ------------------------------------------------------------
  impure function Get  (
    ID        : DynamicArrayIDType ; 
    Index     : integer 
  ) return ElementType is
  begin
    return DynamicArrayStore.Get(ID, Index) ;
  end function Get ;

  impure function Get  (
    ID        : DynamicArrayIDType ; 
    Index     : integer ;
    NumValues : integer 
  ) return ArrayType is
  begin
--    return ArrayType(ReverseIAT(DynamicArrayStore.Get(ID, Index, NumValues))) ;
    return reverse(DynamicArrayStore.Get(ID, Index, NumValues)) ;
  end function Get ;

  ------------------------------------------------------------
  procedure Set (
    ID       : DynamicArrayIDType ; 
    Index    : integer ;
    iValue   : ElementType 
  ) is
  begin
    DynamicArrayStore.Set(ID, Index, iValue) ;
  end procedure Set ;
  
  procedure Set (
    ID       : DynamicArrayIDType ; 
    Index    : integer ;
    iValue   : ArrayType 
  ) is
  begin
--    DynamicArrayStore.Set(ID, Index, ReverseIAT(InternalArrayType(iValue))) ;
    DynamicArrayStore.Set(ID, Index, reverse(iValue)) ;
  end procedure Set ;
  
  ------------------------------------------------------------
  -- GetNext
  --   Remove element(s) 
  impure function GetNext (
    ID        : DynamicArrayIDType 
  ) return ElementType is
  begin
    return DynamicArrayStore.GetNext(ID) ;
  end function GetNext ; 

  impure function GetNext (
    ID        : DynamicArrayIDType ;
    NumValues : natural 
  ) return ArrayType is
  begin
--    return ArrayType(ReverseIAT(DynamicArrayStore.GetNext(ID, NumValues))) ;
    return reverse(DynamicArrayStore.GetNext(ID, NumValues)) ;
  end function GetNext ; 

  ------------------------------------------------------------
  impure function IsEmpty   (ID : DynamicArrayIDType) return boolean is
  begin
    return DynamicArrayStore.IsEmpty(ID) ;
  end function IsEmpty ;

  impure function Deallocate(ID : DynamicArrayIDType) return DynamicArrayIDType is
  begin
    return DynamicArrayStore.Deallocate(ID) ;
  end function Deallocate ; 

  impure function IsInitialized (ID : DynamicArrayIDType) return boolean is
  begin
    return DynamicArrayStore.IsInitialized(ID) ;
  end function IsInitialized ;

    ------------------------------------------------------------
    impure function GetSize (ID : DynamicArrayIDType) return integer is
    ------------------------------------------------------------
    begin
      return DynamicArrayStore.GetSize(ID) ;
    end function GetSize ;

    ------------------------------------------------------------
    impure function GetCapacity (ID : DynamicArrayIDType) return integer is
    ------------------------------------------------------------
    begin
      return DynamicArrayStore.GetCapacity(ID) ;
    end function GetCapacity ;

    ------------------------------------------------------------
    procedure MakeEmpty (ID : DynamicArrayIDType) is
    ------------------------------------------------------------
    begin
      DynamicArrayStore.MakeEmpty(ID) ;
    end procedure MakeEmpty ;

    ------------------------------------------------------------
    procedure SetIndex (ID : DynamicArrayIDType ; Index : integer := FIRST_INDEX) is
    ------------------------------------------------------------
    begin
      DynamicArrayStore.SetIndex(ID) ;
    end procedure SetIndex ;

end package body DynamicArrayGenericPkg ;