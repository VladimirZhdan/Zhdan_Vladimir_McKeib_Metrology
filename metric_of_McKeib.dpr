program metric_of_McKeib;

{$APPTYPE CONSOLE}

uses
  SysUtils, EsConsole;

type
  T_Operator = record
    Value: string;
    Component_Flag: Boolean;
  end;

  T_file_of_source_code = file of Char;

function Check_Insertability_of_Symbol(Symbol: Char): Boolean;
begin
  case Symbol of
    ' ', #13, #10, #9: Result := False;
  else
    Result := True;
  end;
end;

function Check_Insertability_of_Manipulate_Symbol(Symbol: Char; Amount_of_Round_Brackets, Amount_of_Curly_Brackets: Integer;
                                                  Even_number_of_Single_Quotation_Marks, Even_number_of_Quotation_Marks: Boolean): Boolean;
begin
  case Symbol of
    '(', ')', '/', '*': Result := not(Even_number_of_Single_Quotation_Marks or Even_number_of_Quotation_Marks);
    '{', '}': Result := (Amount_of_Round_Brackets = 0) and (not(Even_number_of_Single_Quotation_Marks or Even_number_of_Quotation_Marks));
    #39: Result := not(Even_number_of_Quotation_Marks);
    #34: Result := not(Even_number_of_Single_Quotation_Marks);
    ';': Result := (Amount_of_Round_Brackets = 0) and (Amount_of_Curly_Brackets = 0) and (not(Even_number_of_Single_Quotation_Marks or Even_number_of_Quotation_Marks));
    else
      Result := False;
  end;
end;

function Define_Next_Operator(const Name_of_file_with_Code: string; var Position_in_file_with_Code: LongInt): T_Operator;
var
  Current_symbol: Char;
  Previous_symbol: Char;
  Amount_of_Round_Brackets: Integer;
  Amount_of_Curly_Brackets: Integer;
  Even_number_of_Single_Quotation_Marks: Boolean;
  Even_number_of_Quotation_Marks: Boolean;
  End_of_Operator_Flag: Boolean;
  Insertability_of_Symbol: Boolean;
  File_of_Code: file of Char;
begin
  Result.Value := '';
  Result.Component_Flag := False;
  Previous_symbol := ' ';
  Amount_of_Round_Brackets := 0;
  Amount_of_Curly_Brackets := 0;
  Even_number_of_Single_Quotation_Marks := False;
  Even_number_of_Quotation_Marks := False;
  End_of_Operator_Flag := False;

  assignFile(File_of_Code, Name_of_file_with_Code);
  reset(File_of_Code);
  seek(File_of_Code, Position_in_file_with_Code);
  repeat
    read(File_of_Code, Current_symbol);
    if Check_Insertability_of_Symbol(Current_symbol) then
    begin
      Result.Value := Result.Value + Current_symbol;
      Insertability_of_Symbol := Check_Insertability_of_Manipulate_Symbol(Current_symbol, Amount_of_Round_Brackets, Amount_of_Curly_Brackets,
                                                                           Even_number_of_Single_Quotation_Marks, Even_number_of_Quotation_Marks);
      case Current_symbol of
        '{':
          begin
            if Insertability_of_Symbol then
            begin
              Result.Component_Flag := True;
              Inc(Amount_of_Curly_Brackets);
            end;
          end;
        '(':
          begin
            if Insertability_of_Symbol then
              Inc(Amount_of_Round_Brackets);
          end;
        ')':
          begin
            if Insertability_of_Symbol then
              Dec(Amount_of_Round_Brackets);
          end;
        '}':
          begin
            if Insertability_of_Symbol then
              Dec(Amount_of_Curly_Brackets);
            if (Amount_of_Curly_Brackets = 0)then
              End_of_Operator_Flag := True;
          end;
        ';':
          begin
            if Insertability_of_Symbol then
              End_of_Operator_Flag := True;
          end;
        #39:
          begin
            if Insertability_of_Symbol then
            begin
              Even_number_of_Single_Quotation_Marks := not(Even_number_of_Single_Quotation_Marks);
            end;
          end;
        #34:
          begin
            if Insertability_of_Symbol then
            begin
              Even_number_of_Quotation_Marks := not(Even_number_of_Quotation_Marks);
            end;
          end;
        '/':
          begin
            if (Previous_symbol = '/') and Insertability_of_Symbol then
            begin
              Delete(Result.Value, Length(Result.Value) - 1, 2);
              repeat
                Read(File_of_Code, Current_Symbol);
              until (Current_symbol = #13) or Eof(File_of_Code);

              while not(Current_symbol = #10) and not(Eof(File_of_Code)) do
                Read(File_of_Code, Current_Symbol);
            end;
          end;
        '*':
          begin
            if (Previous_symbol = '/') and Insertability_of_Symbol then
            begin
              Delete(Result.Value, Length(Result.Value) - 1, 2);
              repeat
                Read(File_of_Code, Current_Symbol);
              until (Current_symbol = '*') or Eof(File_of_Code);

              while not(Current_symbol = '/') and not(Eof(File_of_Code)) do
                Read(File_of_Code, Current_Symbol);
            end;
          end;
      end;
      Previous_symbol := Current_symbol;
    end;
  until (End_of_Operator_Flag) or Eof(File_of_Code);
  Position_in_file_with_Code := FilePos(File_of_Code);
  closeFile(File_of_Code);
end;

function Check_Symbol_of_End_Operator(Symbol: Char): Boolean;
begin
  case Symbol of
    '{', ';', ':': Result := True;
  else
    Result := False;
  end;
end;

function Check_Symbol_of_Manipulate_Const(Even_number_of_Quotation_Marks, Even_number_of_Single_Quotation_Marks: Boolean; Amount_of_Round_Brackets: Integer): Boolean;
begin
  Result := not(Even_number_of_Quotation_Marks or Even_number_of_Single_Quotation_Marks);
  Result := Result and (Amount_of_Round_Brackets = 0);
end;

function Define_Length_of_SubOperator_in_Operator(const Value_of_Operator: string): Integer;
var
  Amount_of_Round_Brackets: Integer;
  Even_number_of_Single_Quotation_Marks: Boolean;
  Even_number_of_Quotation_Marks: Boolean;
begin
  Even_number_of_Single_Quotation_Marks := False;
  Even_number_of_Quotation_Marks := False;

  if(Copy(Value_of_Operator, 1, 2) = 'if') or (Copy(Value_of_Operator, 1, 6) = 'switch') then
  begin
    Result := 0;
    repeat
      Inc(Result);
    until (Value_of_Operator[Result] = '(');
    Amount_of_Round_Brackets := 1;
    repeat
      Inc(Result);
      case (Value_of_Operator[Result]) of
        '(':
          begin
            if (not(Even_number_of_Quotation_Marks or Even_number_of_Single_Quotation_Marks)) then
              Inc(Amount_of_Round_Brackets);
          end;
        ')':
          begin
            if (not(Even_number_of_Quotation_Marks or Even_number_of_Single_Quotation_Marks)) then
              Dec(Amount_of_Round_Brackets);
          end;
        #39:
          Even_number_of_Single_Quotation_Marks := not(Even_number_of_Single_Quotation_Marks);
        #34:
          Even_number_of_Quotation_Marks := not(Even_number_of_Quotation_Marks);
      end;
    until (Amount_of_Round_Brackets = 0);
    if (Copy(Value_of_Operator, 1, 4) = 'case') then
    repeat
      Inc(Result);
      case (Value_of_Operator[Result]) of
        #39:
          begin
            if (Even_number_of_Single_Quotation_Marks) then
              Even_number_of_Single_Quotation_Marks := False
            else
              Even_number_of_Single_Quotation_Marks := True;
          end;
        #34:
          begin
            if (Even_number_of_Quotation_Marks) then
              Even_number_of_Quotation_Marks := False
            else
              Even_number_of_Quotation_Marks := True;
          end;
      end;
    until (Value_of_Operator[Result] = ':') and (not(Even_number_of_Quotation_Marks or Even_number_of_Single_Quotation_Marks));
  end
  else
  begin
    Result := 0;
    Amount_of_Round_Brackets := 0;
    repeat
      Inc(Result);
      case (Value_of_Operator[Result]) of
        #39:
          begin
          if (Amount_of_Round_Brackets = 0 ) then
            if (Even_number_of_Single_Quotation_Marks) then
              Even_number_of_Single_Quotation_Marks := False
            else
              Even_number_of_Single_Quotation_Marks := True;
          end;
        #34:
          begin
          if (Amount_of_Round_Brackets = 0 ) then
            if (Even_number_of_Quotation_Marks) then
              Even_number_of_Quotation_Marks := False
            else
              Even_number_of_Quotation_Marks := True;
          end;
        '(':
          begin
            if (not(Even_number_of_Quotation_Marks or Even_number_of_Single_Quotation_Marks)) then
              Amount_of_Round_Brackets := Amount_of_Round_Brackets + 1;
          end;

        ')':
          begin
            if (not(Even_number_of_Quotation_Marks or Even_number_of_Single_Quotation_Marks)) then
              Amount_of_Round_Brackets := Amount_of_Round_Brackets - 1;
          end;
      end;
    until (Check_Symbol_of_End_Operator(Value_of_Operator[Result])) and
              Check_Symbol_of_Manipulate_Const(Even_number_of_Quotation_Marks, Even_number_of_Single_Quotation_Marks, Amount_of_Round_Brackets);
    if (Value_of_Operator[Result] = '{') then
      Dec(Result);
  end;
end;

procedure Remove_extreme_Curly_Brackets_in_Operator(var Value_of_Operator: string);
var
  Amount_of_Round_Brackets: Integer;
  Amount_of_Curly_Brackets: Integer;
  Even_number_of_Single_Quotation_Marks: Boolean;
  Even_number_of_Quotation_Marks: Boolean;
  Position_of_last_Curly_Bracket: Integer;
  Index: Integer;
begin
  Amount_of_Round_Brackets := 0;
  Amount_of_Curly_Brackets := 1;
  Even_number_of_Single_Quotation_Marks := False;
  Even_number_of_Quotation_Marks := False;
  Index := 1;
  repeat
    Index := Index + 1;
    case Value_of_Operator[Index] of
      #39:
          begin
          if (Amount_of_Round_Brackets = 0 ) then
            if (Even_number_of_Single_Quotation_Marks) then
              Even_number_of_Single_Quotation_Marks := False
            else
              Even_number_of_Single_Quotation_Marks := True;
          end;
      #34:
        begin
        if (Amount_of_Round_Brackets = 0 ) then
          if (Even_number_of_Quotation_Marks) then
            Even_number_of_Quotation_Marks := False
          else
            Even_number_of_Quotation_Marks := True;
        end;
      '(':
        begin
          if (not(Even_number_of_Quotation_Marks or Even_number_of_Single_Quotation_Marks)) then
            Amount_of_Round_Brackets := Amount_of_Round_Brackets + 1;
        end;
      ')':
        begin
          if (not(Even_number_of_Quotation_Marks or Even_number_of_Single_Quotation_Marks)) then
            Amount_of_Round_Brackets := Amount_of_Round_Brackets - 1;
        end;
      '{':
          begin
            if (Amount_of_Round_Brackets = 0) and (not(Even_number_of_Quotation_Marks or Even_number_of_Single_Quotation_Marks)) then
              Amount_of_Curly_Brackets := Amount_of_Curly_Brackets + 1;
          end;
      '}':
          begin
            if (Amount_of_Round_Brackets = 0) and (not(Even_number_of_Quotation_Marks or Even_number_of_Single_Quotation_Marks)) then
              Amount_of_Curly_Brackets := Amount_of_Curly_Brackets - 1;
          end;
    end;
  until (Value_of_Operator[Index] = '}') and (Amount_of_Curly_Brackets = 0) and
        (not(Even_number_of_Quotation_Marks or Even_number_of_Single_Quotation_Marks)) and (Amount_of_Round_Brackets = 0);
  Position_of_last_Curly_Bracket := Index;
  Delete(Value_of_Operator, Position_of_last_Curly_Bracket, 1);
  Delete(Value_of_Operator, 1, 1);
end;

function Define_Number_of_McKeib(const Name_of_file_with_Code: string): Integer;
var
  File_of_Code: file of Char;
  Position_in_file_with_Code: LongInt;
  Size_of_file_with_Code: LongInt;
  Current_Operator: T_Operator;
  Next_Operator: T_Operator;
  Amount_of_Arcs: Integer;
  Amount_of_Vertices: Integer;
begin
  Current_Operator.Value := '';
  Next_Operator.Value := '';
  Position_in_file_with_Code := 0;
  Amount_of_Arcs := 1;
  Amount_of_Vertices := 2;

  AssignFile(File_of_Code, Name_of_file_with_Code);
  Reset(File_of_Code);
  Size_of_file_with_Code := FileSize(File_of_Code);
  CloseFile(File_of_Code);
  while (Position_in_file_with_Code <> Size_of_file_with_Code) or (Next_Operator.Value <> '')  do
  begin
    if (Next_Operator.Value = '') then
      Current_Operator := Define_Next_Operator(Name_of_file_with_Code, Position_in_file_with_Code)
    else
    begin
      Current_Operator := Next_Operator;
      Next_Operator.Value := '';
    end;
    if Current_Operator.Value <> '' then
    begin
      if (Copy(Current_Operator.Value, 1, 2) = 'if') then
      begin
        Amount_of_Arcs := Amount_of_Arcs + 3;
        Amount_of_Vertices := Amount_of_Vertices + 2;
        Delete(Current_Operator.Value, 1, Define_Length_of_SubOperator_in_Operator(Current_Operator.Value));
      end
      else
        if (Copy(Current_Operator.Value, 1, 4) = 'else') then
        begin
          Amount_of_Arcs := Amount_of_Arcs + 1;
          Amount_of_Vertices := Amount_of_Vertices + 1;
          Delete(Current_Operator.Value, 1, 4);
        end
        else
          if (Current_Operator.Value[1]) = '{' then
            Remove_extreme_Curly_Brackets_in_Operator(Current_Operator.Value)
          else
            if (Copy(Current_Operator.Value, 1, 6) = 'switch') then
            begin
              Amount_of_Arcs := Amount_of_Arcs + 1;
              Amount_of_Vertices := Amount_of_Vertices + 1;
              Delete(Current_Operator.Value, 1, Define_Length_of_SubOperator_in_Operator(Current_Operator.Value));
            end
            else
              if (Copy(Current_Operator.Value, 1, 4) = 'case') then
              begin
                Amount_of_Arcs := Amount_of_Arcs + 2;
                Amount_of_Vertices := Amount_of_Vertices + 1;
                Delete(Current_Operator.Value, 1, Define_Length_of_SubOperator_in_Operator(Current_Operator.Value));
              end
              else
                if (Copy(Current_Operator.Value, 1, 7) = 'default') then
                begin
                  Amount_of_Arcs := Amount_of_Arcs + 1;
                  Amount_of_Vertices := Amount_of_Vertices + 1;
                  Delete(Current_Operator.Value, 1, 8);
                end
                else
                  Delete(Current_Operator.Value, 1, Define_Length_of_SubOperator_in_Operator(Current_Operator.Value));
      Next_Operator := Current_Operator;
    end;

  end;
  Writeln('Количество дуг(e) = ', Amount_of_Arcs, '; Количество вершин(v) = ', Amount_of_Vertices);
  Writeln('Число компонентов связности графа(p) = 1');
  Result := Amount_of_Arcs - Amount_of_Vertices + 2;
end;




begin
  Writeln(Define_Number_of_McKeib('my_cs.cs'), ' - Цикломатическое число Маккейба (e - v + 2*p)');
  Readln;
end.
