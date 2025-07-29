unit Services.Memory;

interface

type

{ TMemoryServices }

  TMemoryServices = class
  public
    class function GetTotalAllocatedMemory: NativeUInt;
  end;

implementation

{ TMemoryServices }

class function TMemoryServices.GetTotalAllocatedMemory: NativeUInt;
var
  LMMS: TMemoryManagerState;
  LSBTS: TSmallBlockTypeState;
begin
  Result := 0;
  {$WARN SYMBOL_PLATFORM OFF}
  GetMemoryManagerState(LMMS);
  {$WARN SYMBOL_PLATFORM ON}
  for LSBTS in LMMS.SmallBlockTypeStates do
    Inc(Result, LSBTS.InternalBlockSize * LSBTS.AllocatedBlockCount);
  Inc(Result, LMMS.TotalAllocatedMediumBlockSize);
  Inc(Result, LMMS.TotalAllocatedLargeBlockSize);
end;

end.
