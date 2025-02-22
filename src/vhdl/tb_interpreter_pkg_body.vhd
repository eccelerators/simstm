-------------------------------------------------------------------------------
--             Copyright 2023  Ken Campbell
--               All rights reserved.
-------------------------------------------------------------------------------
-- $Author: sckoarn $
--
-- Description :  The the testbench package header file.
--
------------------------------------------------------------------------------
--  This file is part of The VHDL Test Bench Package.
--
--  Redistribution and use in source and binary forms, with or without
--  modification, are permitted provided that the following conditions are met:
--
--  1. Redistributions of source code must retain the above copyright notice,
--     this list of conditions and the following disclaimer.
--
--  2. Redistributions in binary form must reproduce the above copyright notice,
--     this list of conditions and the following disclaimer in the documentation
--     and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
-------------------------------------------------------------------------------
-- Changes:
--
-- Materially changed 2023 by Eccelerators, please diff with original at
-- https://github.com/sckoarn/VHDL-Test-Bench/blob/main/source/tb_pkg_header.vhdl
--
-- Adapt to new fix SimStm language
--
-- ----------------------------------------------------------------------------

library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_base_pkg.all;

package body tb_interpreter_pkg is

    procedure add_instruction(variable inst_list : inout stim_line_ptr;
                              variable var_list : inout var_field_ptr;
                              variable inst : in text_field;
                              variable p1 : in text_field;
                              variable p2 : in text_field;
                              variable p3 : in text_field;
                              variable p4 : in text_field;
                              variable p5 : in text_field;
                              variable p6 : in text_field;
                              variable str_ptr : in stm_text_ptr;
                              variable txt_enclosing_quote : in character;
                              variable sequ_num : inout integer;
                              variable line_num : in integer;
                              variable file_name : in text_line;
                              variable file_idx : in integer;
                              constant stm_value_width : in integer) is
        variable temp_stim_line : stim_line_ptr;
        variable temp_current : stim_line_ptr;
        variable valid : integer;
        variable l : integer;
        variable stm_var_type : t_stm_var_type := NO_VAR_TYPE;
    begin
        valid := 1;
        l := fld_len(inst);
        temp_current := inst_list;
        -- take care of special cases
        if inst(1 to l) = INSTR_VAR then
            stm_var_type := STM_VALUE_TYPE;
        elsif inst(1 to l) = INSTR_CONST then
            stm_var_type := STM_CONST_VALUE_TYPE;
        elsif inst(1 to l) = INSTR_ARRAY then
            stm_var_type := STM_ARRAY_TYPE;
        elsif inst(1 to l) = INSTR_LINES then
            stm_var_type := STM_LINES_TYPE;
        elsif inst(1 to l) = INSTR_FILE then
            stm_var_type := STM_TEXT_TYPE;
        elsif inst(1 to l) = INSTR_BUS then
            stm_var_type := STM_BUS_TYPE;
        elsif inst(1 to l) = INSTR_SIGNAL then
            stm_var_type := STM_SIGNAL_TYPE;
        elsif inst(l) = ':' then
            stm_var_type := STM_LABEL_TYPE;
        end if;
        if stm_var_type /= NO_VAR_TYPE then
            --  add the variable to the variable pool, not considered an instruction
            if stm_var_type /= STM_LABEL_TYPE then
                l := fld_len(p1);
                add_variable(var_list, p1, p2, sequ_num, line_num, file_name, l, stm_var_type, str_ptr, txt_enclosing_quote, stm_value_width);
            else
                add_variable(var_list, inst, p1, sequ_num, line_num, file_name, l, stm_var_type, str_ptr, txt_enclosing_quote, stm_value_width);
            end if;
            valid := 0; --removes this from the instruction list
        end if;
        if valid = 1 then
            -- prepare the new record
            temp_stim_line := new stim_line;
            temp_stim_line.instruction := inst;
            temp_stim_line.inst_field_1 := p1;
            temp_stim_line.inst_field_2 := p2;
            temp_stim_line.inst_field_3 := p3;
            temp_stim_line.inst_field_4 := p4;
            temp_stim_line.inst_field_5 := p5;
            temp_stim_line.inst_field_6 := p6;
            temp_stim_line.txt := str_ptr;
            temp_stim_line.txt_enclosing_quote := txt_enclosing_quote;
            temp_stim_line.line_number := sequ_num;
            temp_stim_line.file_idx := file_idx;
            temp_stim_line.file_line := line_num;
            -- if is not the first instruction
            if inst_list /= null then
                while temp_current.next_rec /= null loop
                    temp_current := temp_current.next_rec;
                end loop;
                temp_current.next_rec := temp_stim_line;
                inst_list.num_of_lines := inst_list.num_of_lines + 1;
            -- other wise is first instruction to be added
            else
                inst_list := temp_stim_line;
                inst_list.num_of_lines := 1;
            end if;
            sequ_num := sequ_num + 1;
            -- print_inst(temp_stim_line);  -- for debug
        end if;
    end procedure;

    procedure add_variable(variable var_list : inout var_field_ptr;
                           variable p1 : in text_field; -- should be var name
                           variable p2 : in text_field; -- should be value
                           variable sequ_num : in integer;
                           variable line_num : in integer;
                           variable name : in text_line;
                           variable length : in integer;
                           constant var_stm_type : in t_stm_var_type;
                           variable str_ptr : in stm_text_ptr;
                           variable txt_enclosing_quote : in character;
                           constant stm_value_width : in integer) is
        variable temp_var : var_field_ptr;
        variable current_ptr : var_field_ptr;
        variable index : integer := 1;

        procedure init_stm_lines_var is
        begin
            temp_var := new var_field(var_value(stm_value_width - 1 downto 0));
            temp_var.var_name := p1; -- direct write of text_field
            temp_var.var_value := to_unsigned(0, stm_value_width);
            temp_var.var_index := index;
            temp_var.var_stm_text := null;
            temp_var.var_stm_text_enclosing_quote := character'val(126);
            temp_var.var_stm_array := null;
            temp_var.var_stm_lines := new t_stm_lines;
            temp_var.var_stm_lines.stm_line_list := null;
            temp_var.var_stm_lines.size := 0;
            temp_var.var_stm_type := var_stm_type;
        end procedure;

        procedure init_stm_array_var is
        begin
            assert stim_to_integer(p2, name, line_num) > 0
            report lf & "error: array size < 1 is not allowed on line " & (integer'image(line_num)) & " of file " & text_line_crop(name)
            severity failure;
            temp_var := new var_field(var_value(stm_value_width - 1 downto 0));
            temp_var.var_name := p1; -- direct write of text_field
            temp_var.var_index := index;
            temp_var.var_value := to_unsigned(0, stm_value_width);
            temp_var.var_stm_text := null;
            temp_var.var_stm_text_enclosing_quote := character'val(126);
            temp_var.var_stm_array := new t_stm_array(0 to stim_to_integer(p2, name, line_num)-1)(stm_value_width - 1 downto 0);
            temp_var.var_stm_lines := null;
            temp_var.var_stm_type := var_stm_type;
        end procedure;

        procedure init_stm_text_var is
        begin
            assert str_ptr /= null
            report lf & "error: missing file name in file declaration " & (integer'image(line_num)) & " of file " & text_line_crop(name)
            severity failure;
            temp_var := new var_field(var_value(stm_value_width - 1 downto 0));
            temp_var.var_name := p1; -- direct write of text_field
            temp_var.var_index := index;
            temp_var.var_value := to_unsigned(0, stm_value_width);
            temp_var.var_stm_text := str_ptr;
            temp_var.var_stm_text_enclosing_quote := txt_enclosing_quote;
            temp_var.var_stm_array := null;
            temp_var.var_stm_lines := null;
            temp_var.var_stm_type := var_stm_type;
        end procedure;

        procedure init_non_inline_var is
        begin
            temp_var := new var_field(var_value(stm_value_width - 1 downto 0));
            temp_var.var_name := p1; -- direct write of text_field
            temp_var.var_index := index;
            temp_var.var_value := stim_to_stm_value(p2, name, line_num, stm_value_width); -- convert text_field to integer
            temp_var.var_stm_text := null;
            temp_var.var_stm_text_enclosing_quote := character'val(126);
            temp_var.var_stm_array := null;
            temp_var.var_stm_lines := null;
            temp_var.var_stm_type := var_stm_type;
        end procedure;

        procedure init_inline_var is
        begin
            temp_var := new var_field(var_value(stm_value_width - 1 downto 0));
            temp_var.var_name(1 to (length - 1)) := p1(1 to (length - 1));
            temp_var.var_index := index;
            temp_var.var_value := to_unsigned(sequ_num, stm_value_width);
            temp_var.var_stm_text := null;
            temp_var.var_stm_text_enclosing_quote := character'val(126);
            temp_var.var_stm_array := null;
            temp_var.var_stm_lines := null;
            temp_var.var_stm_type := var_stm_type;
        end procedure;
    begin
        -- if this is not the first one
        if var_list /= null then
            current_ptr := var_list;
            index := index + 1;
            while current_ptr.next_rec /= null loop
                -- if we have defined the current before then die
                assert current_ptr.var_name /= p1
                report lf & "error: attemping to add a duplicate variable definition " & " on line " & (integer'image(line_num)) & " of file " & text_line_crop(name)
                severity failure;
                current_ptr := current_ptr.next_rec;
                index := index + 1;
            end loop;
            -- if we have defined the current before then die. this checks the last one
            assert current_ptr.var_name /= p1
            report lf & "error: attemping to add a duplicate variable definition " & " on line " & (integer'image(line_num)) & " of file " & text_line_crop(name)
            severity failure;
            if var_stm_type = STM_LINES_TYPE then
                init_stm_lines_var;
                current_ptr.next_rec := temp_var;
            elsif var_stm_type = STM_ARRAY_TYPE then
                init_stm_array_var;
                current_ptr.next_rec := temp_var;
            elsif var_stm_type = STM_TEXT_TYPE then
                init_stm_text_var;
                current_ptr.next_rec := temp_var;
            elsif var_stm_type = STM_LABEL_TYPE then
                init_inline_var;
                current_ptr.next_rec := temp_var;
            else
                init_non_inline_var;
                current_ptr.next_rec := temp_var;
            end if;
        -- this is the first one
        else
            if var_stm_type = STM_LINES_TYPE then
                init_stm_lines_var;
            elsif var_stm_type = STM_ARRAY_TYPE then
                init_stm_array_var;
            elsif var_stm_type = STM_TEXT_TYPE then
                init_stm_text_var;
            elsif var_stm_type = STM_LABEL_TYPE then
                init_inline_var;
            else
                init_non_inline_var;
            end if;
            var_list := temp_var;
        end if;
    end procedure;

    procedure access_variable(variable var_list : in var_field_ptr;
                              variable var : in text_field;
                              variable value : out integer;
                              variable valid : out integer;
                              constant stm_value_width : in integer) is
        variable stmvalue : unsigned(stm_value_width - 1 downto 0) := to_unsigned(0, stm_value_width);
    begin
        access_variable(var_list, var, stmvalue, valid);
        value := to_integer(stmvalue(30 downto 0));
    end procedure;

    procedure access_variable(variable var_list : in var_field_ptr;
                              variable var : in text_field;
                              variable value : out unsigned;
                              variable valid : out integer) is
        variable l : integer;
        variable var_ptr : var_field_ptr;
        variable temp_field : text_field;
        variable ptr : integer := 0; -- 0 is index, 1 is pointer
        variable is_defined : boolean := false;
    begin
        l := fld_len(var);
        valid := 0;
        -- if the variable is a special
        if var(1) = '=' then
            value := to_unsigned(0, value'length);
            valid := 1;
        elsif var(1 to 2) = ">=" then
            value := to_unsigned(4, value'length);
            valid := 1;
        elsif var(1 to 2) = "<=" then
            value := to_unsigned(5, value'length);
            valid := 1;
        elsif var(1) = '>' then
            value := to_unsigned(1, value'length);
            valid := 1;
        elsif var(1) = '<' then
            value := to_unsigned(2, value'length);
            valid := 1;
        elsif var(1 to 2) = "!=" then
            value := to_unsigned(3, value'length);
            valid := 1;
        else
            if var(1) = '$' then
                ptr := 1; -- this is a pointer
                for i in 2 to l loop
                    temp_field(i - 1) := var(i);
                end loop;
            else
                temp_field := var;
            end if;
            assert var_list /= null
            report lf & "error: no variables are defined." & lf
            severity failure;
            var_ptr := var_list;
            while var_ptr.next_rec /= null loop
                -- if we have a match
                if fld_equal(temp_field, var_ptr.var_name) then
                    if ptr = 1 then
                        value := var_ptr.var_value;
                        valid := 1;
                        is_defined := true;
                    else
                        value := to_unsigned(var_ptr.var_index, value'length);
                        valid := 1;
                        is_defined := true;
                    end if;
                    exit;
                end if;
                var_ptr := var_ptr.next_rec;
            end loop;
            -- if we have a match and was the last record
            if var_ptr.next_rec = null then
                if fld_equal(temp_field, var_ptr.var_name) then
                    if ptr = 1 then
                        value := var_ptr.var_value;
                        valid := 1;
                        is_defined := true;
                    else
                        value := to_unsigned(var_ptr.var_index, value'length);
                        valid := 1;
                        is_defined := true;
                    end if;
                end if;
            end if;
            assert is_defined
            report lf & "error: variable is not defined " & temp_field & lf
            severity failure;
        end if;
    end procedure;

    procedure access_inst_sequ(variable inst_sequ : in stim_line_ptr;
                               variable var_list : in var_field_ptr;
                               variable file_list : in file_def_ptr;
                               variable sequ_num : in integer;
                               variable inst : out text_field;
                               variable p1 : out unsigned;
                               variable p2 : out unsigned;
                               variable p3 : out unsigned;
                               variable p4 : out unsigned;
                               variable p5 : out unsigned;
                               variable p6 : out unsigned;
                               variable txt : out stm_text_ptr;
                               variable txt_enclosing_quote : out character;
                               variable inst_len : out integer;
                               variable fname : out text_line;
                               variable file_line : out integer;
                               variable last_num : inout integer;
                               variable last_ptr : inout stim_line_ptr) is
        variable temp_text_field : text_field;
        variable inst_ptr : stim_line_ptr;
        variable valid : integer;
        variable line : integer; -- value of the file_line
        variable file_name : text_line;
        variable tmp_int : integer;
        variable temp_fn_prt : file_def_ptr;
    begin
        -- get to the instruction indicated by sequ_num
        -- check to see if this sequence is before the last
        --    so search from start
        if last_num > sequ_num then
            inst_ptr := inst_sequ;
            while inst_ptr.next_rec /= null loop
                if inst_ptr.line_number = sequ_num then
                    exit;
                else
                    inst_ptr := inst_ptr.next_rec;
                end if;
            end loop;
        -- else is equal or greater, so search forward
        else
            inst_ptr := last_ptr;
            while inst_ptr.next_rec /= null loop
                if inst_ptr.line_number = sequ_num then
                    exit;
                else
                    inst_ptr := inst_ptr.next_rec;
                end if;
            end loop;
        end if;
        -- update the last sequence number and record pointer
        last_num := sequ_num;
        last_ptr := inst_ptr;
        -- output the instruction and its length
        inst := inst_ptr.instruction;
        inst_len := fld_len(inst_ptr.instruction);
        file_line := inst_ptr.file_line;
        line := inst_ptr.file_line;
        -- recover the file name this line came from
        temp_fn_prt := file_list;
        tmp_int := inst_ptr.file_idx;
        while temp_fn_prt.next_rec /= null loop
            if temp_fn_prt.rec_idx = tmp_int then
                exit;
            end if;
            temp_fn_prt := temp_fn_prt.next_rec;
        end loop;
        for i in 1 to fname'high loop
            file_name(i) := temp_fn_prt.file_name(i);
            fname(i) := temp_fn_prt.file_name(i);
        end loop;
        txt := inst_ptr.txt;
        txt_enclosing_quote := inst_ptr.txt_enclosing_quote;
        temp_text_field := inst_ptr.inst_field_1;
        if temp_text_field(1) /= nul then
            if is_digit(temp_text_field(1)) then
                p1 := stim_to_stm_value(temp_text_field, file_name, line, p1'length);
            else
                access_variable(var_list, temp_text_field, p1, valid);
                assert valid = 1
                report lf & "error: first variable on stimulus line " & (integer'image(line)) & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
        temp_text_field := inst_ptr.inst_field_2;
        if temp_text_field(1) /= nul then
            if is_digit(temp_text_field(1)) then
                p2 := stim_to_stm_value(temp_text_field, file_name, line, p2'length);
            else
                access_variable(var_list, temp_text_field, p2, valid);
                assert valid = 1
                report lf & "error: second variable on stimulus line " & (integer'image(line)) & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
        temp_text_field := inst_ptr.inst_field_3;
        if temp_text_field(1) /= nul then
            if is_digit(temp_text_field(1)) then
                p3 := stim_to_stm_value(temp_text_field, file_name, line, p3'length);
            else
                access_variable(var_list, temp_text_field, p3, valid);
                assert valid = 1
                report lf & "error: third variable on stimulus line " & (integer'image(line)) & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
        temp_text_field := inst_ptr.inst_field_4;
        if temp_text_field(1) /= nul then
            if is_digit(temp_text_field(1)) then
                p4 := stim_to_stm_value(temp_text_field, file_name, line, p4'length);
            else
                access_variable(var_list, temp_text_field, p4, valid);
                assert valid = 1
                report lf & "error: forth variable on stimulus line " & (integer'image(line)) & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
        temp_text_field := inst_ptr.inst_field_5;
        if temp_text_field(1) /= nul then
            if is_digit(temp_text_field(1)) then
                p5 := stim_to_stm_value(temp_text_field, file_name, line, p5'length);
            else
                access_variable(var_list, temp_text_field, p5, valid);
                assert (valid = 1)
                report lf & "error: fifth variable on stimulus line " & (integer'image(line)) & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
        temp_text_field := inst_ptr.inst_field_6;
        if temp_text_field(1) /= nul then
            if is_digit(temp_text_field(1)) then
                p6 := stim_to_stm_value(temp_text_field, file_name, line, p6'length);
            else
                access_variable(var_list, temp_text_field, p6, valid);
                assert valid = 1
                report lf & "error: sixth variable on stimulus line " & (integer'image(line)) & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
    end procedure;

    procedure dump_inst_sequ(variable inst_sequ : in stim_line_ptr; file_list : inout file_def_ptr) is
        variable v_sequ : stim_line_ptr;
        variable tmp_txt : stm_text;
        variable fn : text_line;
        procedure dump is
        begin
            print("++++ -----------------------------------------------------------------");
            print("++++ instruction is " & v_sequ.instruction);
            txt_to_string(v_sequ.txt, tmp_txt);
            print("++++ text: " & tmp_txt);
            print("++++ par1: " & v_sequ.inst_field_1);
            print("++++ par2: " & v_sequ.inst_field_2);
            print("++++ par3: " & v_sequ.inst_field_3);
            print("++++ par4: " & v_sequ.inst_field_4);
            print("++++ par5: " & v_sequ.inst_field_5);
            print("++++ par6: " & v_sequ.inst_field_6);
            print("++++ internal sequence linenumber: " & to_str(v_sequ.line_number));
            print("++++ instruction file linenumber: " & to_str(v_sequ.file_line));
            print("++++ instruction file idx: " & to_str(v_sequ.file_idx));
            get_instruction_file_name(file_list, v_sequ.file_idx, fn);
            print("++++ instruction file name: " & fn);
        end procedure;
    begin
        v_sequ := inst_sequ;
        print("++++ -----------------------------------------------------------------");
        while v_sequ.next_rec /= null loop
            dump;
            v_sequ := v_sequ.next_rec;
        end loop;
        -- get the last one
        dump;
    end procedure;

    procedure dump_variables(variable var_list : in var_field_ptr;
                             constant stm_value_width : in integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        print("---- -----------------------------------------------------------------");
        print("---- -- dump variables start -----------------------------------------");
        while ptr.next_rec /= null loop
            dump_var_field(ptr, stm_value_width);
            ptr := ptr.next_rec;
        end loop;
        -- the last one
        dump_var_field(ptr, stm_value_width);
    end procedure;

    procedure dump_file_defs(file_list : inout file_def_ptr) is
        variable tmp_file_def_ptr : file_def_ptr;
        variable index : integer;
    begin
        print("---- -----------------------------------------------------------------");
        print("---- -- dump file defs start -----------------------------------------");
        index := 0;
        tmp_file_def_ptr := file_list;
        while tmp_file_def_ptr.next_rec /= null loop
            print_file_def(file_list, index);
            tmp_file_def_ptr := tmp_file_def_ptr.next_rec;
            index := index + 1;
        end loop;
        -- the last one
        print_file_def(file_list, index);
    end procedure;

    procedure dump_var_field(variable ptr : var_field_ptr;
                             constant stm_value_width : in integer) is
        variable std_line : line;
        variable tmp_str : stm_text;
        variable tmp_str_ptr : stm_text_ptr;
        variable stm_line_ptr : t_stm_line_ptr;
        variable success : boolean;
        variable array_index : integer;
        variable array_value : unsigned(stm_value_width - 1 downto 0);
        variable value_std_logic_vector : std_logic_vector(stm_value_width - 1 downto 0);
        variable tmp_std_line_print : line;
        variable stm_array : t_stm_array_ptr;
    begin
        print("-----------------------------------------------------------------");
        print("---- var_name: " & ptr.var_name);
        print("---- var_index: " & to_str(ptr.var_index));
        print("---- var_value: 0x" & to_str_hex(ptr.var_value));
        if ptr.var_stm_type = STM_VALUE_TYPE then
            print("---- var_stm_type: STM_VALUE_TYPE");
        elsif ptr.var_stm_type = STM_CONST_VALUE_TYPE then
            print("---- var_stm_type: STM_CONST_VALUE_TYPE");
        elsif ptr.var_stm_type = STM_CONST_VALUE_TYPE then
            print("---- var_stm_type: STM_CONST_VALUE_TYPE");
        elsif ptr.var_stm_type = STM_TEXT_TYPE then
            print("---- var_stm_type: STM_TEXT_TYPE");
            txt_to_string(ptr.var_stm_text, tmp_str);
            print("---- var_stm_text: " & tmp_str);
            print("---- var_stm_text_enclosing_quote: " & ptr.var_stm_text_enclosing_quote);
        elsif ptr.var_stm_type = STM_ARRAY_TYPE then
            print("---- var_stm_type: STM_ARRAY_TYPE");
            stm_array := ptr.var_stm_array;
            for i in 0 to stm_array'high loop
                array_index := i;
                array_value := ptr.var_stm_array(array_index);
                print("-------- index: " & to_str(array_index) & ", value: " & to_str_hex(array_value));
            end loop;
        elsif ptr.var_stm_type = STM_LINES_TYPE then
            print("---- var_stm_type: STM_LINES_TYPE");
            assert ptr.var_stm_lines /= null
            report " error: stm_lines_ptr pointer is null "
            severity failure;
            print("-------- stm_lines.size: " & to_str(ptr.var_stm_lines.size));
            stm_line_ptr := ptr.var_stm_lines.stm_line_list;
            while stm_line_ptr /= null loop
                print("-------- stm_line_ptr.line_number: " & to_str(stm_line_ptr.line_number));
                if stm_line_ptr.line_type = STM_LINE_TEXT_TYPE then
                    print("-------- stm_line_ptr.line_type: STM_LINE_TEXT_TYPE");
                    tmp_str_ptr := new stm_text;
                    get_stm_text_ptr_from_line(std_line, tmp_str_ptr);
                    txt_print(tmp_str_ptr);
                elsif stm_line_ptr.line_type = STM_LINE_ARRAY_TYPE then
                    print("-------- stm_line_ptr.line_type: STM_LINE_ARRAY_TYPE");
                    success := true;
                    print("-------- stm_line_ptr.line_content'length before reading: " & to_str(stm_line_ptr.line_content'length));
                    array_index := 0;
                    tmp_std_line_print := new string'(stm_line_ptr.line_content.all);
                    while success loop
                        hread(tmp_std_line_print, value_std_logic_vector, success);
                        if success then
                            array_value := unsigned(value_std_logic_vector);
                            print("-------- index: " & to_str(array_index) & ", value: " & to_str_hex(array_value));
                        end if;
                        array_index := array_index + 1;
                    end loop;
                    print("-------- stm_line_ptr.line_content'length after reading: " & to_str(stm_line_ptr.line_content'length));
                end if;
                stm_line_ptr := stm_line_ptr.next_stm_line;
            end loop;
        elsif ptr.var_stm_type = STM_BUS_TYPE then
            print("---- var_stm_type: STM_BUS_TYPE");
        elsif ptr.var_stm_type = STM_SIGNAL_TYPE then
            print("---- var_stm_type: STM_SIGNAL_TYPE");
        elsif ptr.var_stm_type = STM_LABEL_TYPE then
            print("---- var_stm_type: STM_LABEL_TYPE");
        elsif ptr.var_stm_type = NO_VAR_TYPE then
            print("---- var_stm_type: NO_VAR_TYPE");
        end if;
    end procedure;

    procedure file_read_line(file file_name : text;
                             variable file_line : out text_line) is
        variable index : integer; -- index into string
        variable rline : line;
    begin
        index := 1; -- set index to begin of string
        file_line := (others => nul);
        if not endfile(file_name) then
            readline(file_name, rline);
            while rline'right /= (index - 1) and rline'length /= 0 loop
                file_line(index) := rline(index);
                index := index + 1;
            end loop;
        end if;
    end procedure;

    procedure index_variable(variable var_list : in var_field_ptr;
                             variable index_stm_value : in unsigned;
                             variable value : out unsigned;
                             variable valid : out integer) is
        variable index : integer;
    begin
        index := to_integer(index_stm_value(30 downto 0));
        index_variable(var_list, index, value, valid);
    end procedure;

    procedure index_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable value : out unsigned;
                             variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index then
                value := ptr.var_value;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if ptr.var_index = index then
            value := ptr.var_value;
            valid := 1;
        end if;
    end procedure;

    procedure index_variable(variable var_list : in var_field_ptr;
                             variable index_stm_value : in unsigned;
                             variable var_stm_text : out stm_text_ptr;
                             variable var_stm_text_enclosing_quote : out character;
                             variable valid : out integer) is
        variable index : integer;
    begin
        index := to_integer(index_stm_value(30 downto 0));
        index_variable(var_list, index, var_stm_text, var_stm_text_enclosing_quote, valid);
    end procedure;

    procedure index_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_stm_text : out stm_text_ptr;
                             variable var_stm_text_enclosing_quote : out character;
                             variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index then
                var_stm_text := ptr.var_stm_text;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if ptr.var_index = index then
            var_stm_text := ptr.var_stm_text;
            var_stm_text_enclosing_quote := ptr.var_stm_text_enclosing_quote;
            valid := 1;
        end if;
    end procedure;

    procedure index_variable(variable var_list : in var_field_ptr;
                             variable index_stm_value : in unsigned;
                             variable stm_array : out t_stm_array_ptr;
                             variable valid : out integer) is
        variable index : integer;
    begin
        index := to_integer(index_stm_value(30 downto 0));
        index_variable(var_list, index, stm_array, valid);
    end procedure;

    procedure index_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable stm_array : out t_stm_array_ptr;
                             variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index then
                stm_array := ptr.var_stm_array;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if ptr.var_index = index then
            stm_array := ptr.var_stm_array;
            valid := 1;
        end if;
    end procedure;

    procedure index_variable(variable var_list : in var_field_ptr;
                             variable index_stm_value : in unsigned;
                             variable stm_lines : out t_stm_lines_ptr;
                             variable valid : out integer) is
        variable index : integer;
    begin
        index := to_integer(index_stm_value(30 downto 0));
        index_variable(var_list, index, stm_lines, valid);
    end procedure;

    procedure index_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable stm_lines : out t_stm_lines_ptr;
                             variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index then
                stm_lines := ptr.var_stm_lines;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if ptr.var_index = index then
            stm_lines := ptr.var_stm_lines;
            valid := 1;
        end if;
    end procedure;

    procedure print_file_def(file_list : inout file_def_ptr; index : in integer) is
        variable tmp_file_def_ptr : file_def_ptr;
    begin
        tmp_file_def_ptr := file_list;
        while tmp_file_def_ptr.next_rec /= null loop
            if tmp_file_def_ptr.rec_idx = index then
                exit;
            else
                tmp_file_def_ptr := tmp_file_def_ptr.next_rec;
            end if;
        end loop;
        print(".... -----------------------------------------------------------------");
        print(".... file_def is ");
        print(".... index: " & to_str(tmp_file_def_ptr.rec_idx));
        print(".... name: " & tmp_file_def_ptr.file_name);
    end procedure;

    procedure print_inst(variable inst_sequ : in stim_line_ptr; v_line : in integer; file_list : inout file_def_ptr) is
        variable inst_ptr : stim_line_ptr;
        variable tmp_txt : stm_text;
        variable fn : text_line;
    begin
        inst_ptr := inst_sequ;
        while inst_ptr.next_rec /= null loop
            if inst_ptr.line_number = v_line then
                exit;
            else
                inst_ptr := inst_ptr.next_rec;
            end if;
        end loop;
        print(".... -----------------------------------------------------------------");
        print(".... instruction is " & inst_ptr.instruction);
        print(".... par1: " & inst_ptr.inst_field_1);
        print(".... par2: " & inst_ptr.inst_field_2);
        print(".... par3: " & inst_ptr.inst_field_3);
        print(".... par4: " & inst_ptr.inst_field_4);
        print(".... par5: " & inst_ptr.inst_field_5);
        print(".... par6: " & inst_ptr.inst_field_6);
        txt_to_string(inst_ptr.txt, tmp_txt);
        print(".... text: " & tmp_txt);
        print(".... internal sequence linenumber: " & to_str(inst_ptr.line_number));
        print(".... instruction file linenumber: " & to_str(inst_ptr.file_line));
        print(".... instruction file idx: " & to_str(inst_ptr.file_idx));
        get_instruction_file_name(file_list, inst_ptr.file_idx, fn);
        print(".... instruction file name: " & fn);
    end procedure;

    procedure get_inst_field_1(variable inst_sequ : in stim_line_ptr; v_line : in integer; inst_field_1 : out text_field) is
        variable inst_ptr : stim_line_ptr;
    begin
        inst_ptr := inst_sequ;
        while inst_ptr.next_rec /= null loop
            if inst_ptr.line_number = v_line then
                exit;
            else
                inst_ptr := inst_ptr.next_rec;
            end if;
        end loop;
        inst_field_1 := inst_ptr.inst_field_1;
    end procedure;

    procedure read_include_file(constant path_name : string;
                                variable name : text_line;
                                variable sequ_numb : inout integer;
                                variable file_list : inout file_def_ptr;
                                variable inst_set : inout inst_def_ptr;
                                variable var_list : inout var_field_ptr;
                                variable inst_sequ : inout stim_line_ptr;
                                variable status : inout integer;
                                constant stm_value_width : in integer) is
        variable l : text_line; -- the line
        variable l_num : integer; -- line number file
        variable sequ_line : integer; -- line number program
        variable t1 : text_field;
        variable t2 : text_field;
        variable t3 : text_field;
        variable t4 : text_field;
        variable t5 : text_field;
        variable t6 : text_field;
        variable t7 : text_field;
        variable t_txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
        variable valid : integer;
        variable v_inst_ptr : inst_def_ptr;
        variable v_var_prt : var_field_ptr;
        variable v_sequ_ptr : stim_line_ptr;
        variable v_len : integer;
        variable v_stat : file_open_status;
        variable v_tmp_fn_ptr : file_def_ptr;
        variable v_new_fn : integer;
        variable v_tmp_fn : file_def_ptr;
        variable present : boolean;
        variable v_iname : text_line;
        variable include_file_path_name : text_line;
        variable v_ostat : integer;
        file include_file : text; -- file declaration for includes

    begin
        sequ_line := sequ_numb;
        v_tmp_fn_ptr := file_list;
        for i in 1 to path_name'high loop
            include_file_path_name(i) := path_name(i);
        end loop;
        for i in 1 to max_str_len - path_name'high loop
            include_file_path_name(i + path_name'high) := name(i);
        end loop;
        --  open include file
        file_open(v_stat, include_file, text_line_crop(include_file_path_name), read_mode);
        if v_stat /= open_ok then
            print("error: unable to open include file  " & text_line_crop(include_file_path_name));
            status := 1;
            return;
        end if;
        l_num := 1; -- initialize line number
        --  the file is opened, put it on the file name ll
        while v_tmp_fn_ptr.next_rec /= null loop
            v_tmp_fn_ptr := v_tmp_fn_ptr.next_rec;
        end loop;
        v_new_fn := v_tmp_fn_ptr.rec_idx + 1;
        v_tmp_fn := new file_def;
        v_tmp_fn_ptr.next_rec := v_tmp_fn;
        v_tmp_fn.rec_idx := v_new_fn;
        --  nul the text line
        v_tmp_fn.file_name := (others => nul);
        for i in 1 to name'high loop
            v_tmp_fn.file_name(i) := name(i);
        end loop;
        v_tmp_fn.next_rec := null;
        v_inst_ptr := inst_set;
        v_var_prt := var_list;
        v_sequ_ptr := inst_sequ;
        -- while not the end of file read it
        while not endfile(include_file) loop
            file_read_line(include_file, l);
            --  tokenize the line
            tokenize_line(l, t1, t2, t3, t4, t5, t6, t7, t_txt, txt_enclosing_quote, valid);
            v_len := fld_len(t1);
            if t1(1 to v_len) = "include" then
                -- if file name is in par2
                if valid = 2 then
                    v_iname := (others => nul);
                    for i in 1 to max_field_len loop
                        v_iname(i) := t2(i);
                    end loop;
                -- elsif the text string is not null
                elsif t_txt /= null then
                    v_iname := (others => nul);
                    for i in 1 to c_stm_text_len loop
                        v_iname(i) := t_txt(i);
                        if t_txt(i) = txt_enclosing_quote then
                            v_iname(i) := nul;
                            exit;
                        end if;
                    end loop;
                else
                    assert false
                    report lf & "error:  include instruction is missing included file name paramater , found at:" & lf & "line " & (integer'image(l_num)) & " in file " & include_file_path_name & lf
                    severity failure;
                end if;
                print("nested include found in : " & include_file_path_name);
                check_presence_instruction_file_name(file_list, text_line_crop(v_iname), present);
                if present then
                    print("nested include found: not loading file since already present " & text_line_crop(v_iname));
                else
                    print("nested include found: loading file " & path_name & v_iname);
                    read_include_file(path_name, v_iname, sequ_line, v_tmp_fn, v_inst_ptr, v_var_prt, v_sequ_ptr, v_ostat, stm_value_width);
                    -- if include file not found
                    if v_ostat = 1 then
                        exit;
                    end if;
                end if;
            -- if there was valid tokens
            elsif valid /= 0 then
                check_valid_inst(t1, v_inst_ptr, valid, l_num, name);
                add_instruction(v_sequ_ptr, v_var_prt, t1, t2, t3, t4, t5, t6, t7,
                                t_txt, txt_enclosing_quote, sequ_line, l_num, name, v_new_fn, stm_value_width);
            end if;
            l_num := l_num + 1;
        end loop; -- end loop read file
        file_close(include_file);
        sequ_numb := sequ_line;
        inst_set := v_inst_ptr;
        var_list := v_var_prt;
        inst_sequ := v_sequ_ptr;
    end procedure;

    procedure read_instruction_file(constant path_name : string;
                                    constant file_name : string;
                                    variable inst_set : inout inst_def_ptr;
                                    variable var_list : inout var_field_ptr;
                                    variable inst_sequ : inout stim_line_ptr;
                                    variable file_list : inout file_def_ptr;
                                    constant stm_value_width : in integer) is
        variable l : text_line; -- the line
        variable l_num : integer; -- line number file
        variable sequ_line : integer; -- line number program
        variable t1 : text_field;
        variable t2 : text_field;
        variable t3 : text_field;
        variable t4 : text_field;
        variable t5 : text_field;
        variable t6 : text_field;
        variable t7 : text_field;
        variable t_txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
        variable valid : integer;
        variable v_ostat : integer;
        variable v_inst_ptr : inst_def_ptr;
        variable v_var_prt : var_field_ptr;
        variable v_sequ_ptr : stim_line_ptr;
        variable v_len : integer;
        variable v_stat : file_open_status;
        variable v_name : text_line;
        variable v_iname : text_line;
        variable v_tmp_fn : file_def_ptr;
        variable v_fn_idx : integer;
    begin
        -- open the stimulus_file and check
        file_open(v_stat, stimulus, path_name & file_name, read_mode);
        assert v_stat = open_ok
        report lf & "error: unable to open stimulus_file  " & path_name & file_name
        severity failure;
        -- copy file name to type text_line
        for i in 1 to path_name'high loop
            v_name(i) := path_name(i);
        end loop;
        for i in 1 to file_name'high loop
            v_name(i + path_name'high) := file_name(i);
        end loop;
        -- the first item on the file names link list
        file_list := null;
        v_tmp_fn := new file_def;
        v_tmp_fn.rec_idx := 1;
        v_fn_idx := 1;
        --  nul the text line
        v_tmp_fn.file_name := (others => nul);
        for i in 1 to path_name'high loop
            v_tmp_fn.file_name(i) := path_name(i);
        end loop;
        for i in 1 to file_name'high loop
            v_tmp_fn.file_name(i + path_name'high) := file_name(i);
        end loop;
        v_tmp_fn.next_rec := null;
        l_num := 1;
        sequ_line := 1;
        v_ostat := 0;
        v_inst_ptr := inst_set;
        v_var_prt := var_list;
        v_sequ_ptr := inst_sequ;
        -- while not the end of file read it
        while not endfile(stimulus) loop
            file_read_line(stimulus, l);
            --  tokenize the line
            tokenize_line(l, t1, t2, t3, t4, t5, t6, t7, t_txt, txt_enclosing_quote, valid);
            v_len := fld_len(t1);
            -- if there is an include instruction
            if t1(1 to v_len) = "include" then
                -- if file name is in par2
                if valid = 2 then
                    v_iname := (others => nul);
                    for i in 1 to max_field_len loop
                        v_iname(i) := t2(i);
                    end loop;
                -- elsif the text string is not null
                elsif t_txt /= null then
                    v_iname := (others => nul);
                    for i in 1 to c_stm_text_len loop
                        v_iname(i) := t_txt(i);
                        if t_txt(i) = txt_enclosing_quote then
                            v_iname(i) := nul;
                            exit;
                        end if;
                    end loop;
                else
                    assert false
                    report lf & "error:  include instruction has not file name included.  found on" & lf & "line " & (integer'image(l_num)) & " in file " & path_name & file_name & lf
                    severity failure;
                end if;
                print("include found: loading file " & path_name & v_iname);
                read_include_file(path_name, v_iname, sequ_line, v_tmp_fn, v_inst_ptr, v_var_prt, v_sequ_ptr, v_ostat, stm_value_width);
                -- if include file not found
                if v_ostat = 1 then
                    exit;
                end if;
            -- if there was valid tokens
            elsif valid /= 0 then
                check_valid_inst(t1, v_inst_ptr, valid, l_num, v_name);
                add_instruction(v_sequ_ptr, v_var_prt, t1, t2, t3, t4, t5, t6, t7, t_txt, txt_enclosing_quote,
                                sequ_line, l_num, v_name, v_fn_idx, stm_value_width);
            end if;
            l_num := l_num + 1;
        end loop; -- end loop read file
        file_close(stimulus); -- close the file when done
        assert v_ostat = 0
        report lf & "include file specified on line " & (integer'image(l_num)) & " in file " & path_name & file_name & " was not found! test terminated" & lf
        severity failure;
        inst_set := v_inst_ptr;
        var_list := v_var_prt;
        inst_sequ := v_sequ_ptr;
        file_list := v_tmp_fn;
        --  now that all the stimulus is loaded, test for invalid variables
        test_inst_sequ(inst_sequ, v_tmp_fn, var_list, stm_value_width);
    end procedure;

    procedure stm_text_substitude_wvar(variable var_list : in var_field_ptr;
                                       variable ptr : in stm_text_ptr;
                                       variable txt_enclosing_quote : in character;
                                       variable stack_ptr : integer;
                                       variable stack_called_files : stack_text_line_array;
                                       variable stack_called_file_line_numbers : stack_numbers_array;
                                       variable stack_called_labels : stack_text_field_array;
                                       variable stm_text_substituded : out stm_text;
                                       constant stm_value_width : in integer) is
        variable src_i : integer;
        variable src_tail_i : integer;
        variable dest_i : integer;
        variable f_src_i : integer;
        variable f_dest_i : integer;
        variable f_dest_txt_str : stm_text;
        variable k : integer;
        variable src_tail_begin : integer;
        variable dest_txt_str : stm_text;
        variable v1 : unsigned(stm_value_width - 1 downto 0);
        variable valid : integer;
        variable tmp_field : text_field;
        variable tmp_i : integer;
        variable input_txt : stm_text;

        variable insert_var : boolean;
        variable format : base;
        variable insert_call_stack_label : boolean;
        variable previous_level : integer;
        variable insert_call_stack_file : boolean;
        variable insert_call_stack_line_number : boolean;
        variable stack_called_file : text_field;
        variable stack_called_file_line_number : integer;
        variable stack_called_label : text_field;

    begin
        if ptr = null then
            return;
        end if;
        txt_to_string(ptr, input_txt);
        -- determine variables tail_start in src string
        src_i := 1;
        src_tail_begin := 0;
        while src_i <= c_stm_text_len loop
            if src_i > 1 then
                if ptr(src_i - 1) = '\' and ptr(src_i) = txt_enclosing_quote then
                    src_i := src_i + 1;
                else
                    if ptr(src_i) = txt_enclosing_quote then
                        src_tail_begin := src_i;
                        exit;
                    end if;
                    src_i := src_i + 1;
                end if;
            else
                if ptr(src_i) = txt_enclosing_quote then
                    src_tail_begin := src_i;
                    exit;
                end if;
                src_i := src_i + 1;
            end if;
        end loop;
        src_i := 1;
        src_tail_i := src_tail_begin;
        dest_i := 1;
        dest_txt_str := (others => nul);
        while src_i <= src_tail_begin and dest_i <= c_stm_text_len loop
            if src_i < src_tail_begin then
                if ptr(src_i) = '\' and ptr(src_i + 1) = txt_enclosing_quote then
                    src_i := src_i + 1;
                end if;
            end if;

            -- copy until next '{'
            while src_i < src_tail_begin and dest_i <= c_stm_text_len loop
                if ptr(src_i) = '{' then
                    exit;
                else
                    dest_txt_str(dest_i) := ptr(src_i);
                    src_i := src_i + 1;
                    dest_i := dest_i + 1;
                end if;
            end loop;
            if src_i = src_tail_begin then
                -- src end reached
                f_src_i := 1;
                f_dest_i := 1;
                f_dest_txt_str := (others => nul);
                while f_src_i < dest_i loop
                    if f_src_i + 1 < dest_i then
                        if dest_txt_str(f_src_i) = '\' and dest_txt_str(f_src_i + 1) = txt_enclosing_quote then
                            -- skip '/' before txt_enclosing_quote
                            f_src_i := f_src_i + 1;
                            f_dest_txt_str(f_dest_i) := dest_txt_str(f_src_i);
                            f_src_i := f_src_i + 1;
                            f_dest_i := f_dest_i + 1;
                        else
                            -- don't skip '/' before others but txt_enclosing_quote
                            f_dest_txt_str(f_dest_i) := dest_txt_str(f_src_i);
                            f_src_i := f_src_i + 1;
                            f_dest_i := f_dest_i + 1;
                        end if;
                    else
                        f_dest_txt_str(f_dest_i) := dest_txt_str(f_src_i);
                        f_src_i := f_src_i + 1;
                        f_dest_i := f_dest_i + 1;
                    end if;
                end loop;
                stm_text_substituded := f_dest_txt_str;
                return;
            end if;
            -- place to embed a var found
            insert_call_stack_label := false;
            insert_call_stack_file := false;
            insert_call_stack_line_number := false;
            if ptr(src_i) = '{' then
                src_i := src_i + 1;
                format := hex;
                insert_var := true;
                while src_i < src_tail_begin and dest_i <= c_stm_text_len loop
                    if ptr(src_i) = '}' then
                        -- default insert variable hex
                        exit;
                    else
                        -- skip until next '}'
                        if ptr(src_i) = ':' then
                            -- insert variable decimal, binary or octal
                            src_i := src_i + 1;
                            if src_i = src_tail_begin then
                                exit;
                            end if;
                            if ptr(src_i) = 'd' then
                                format := dec;
                            elsif ptr(src_i) = 'b' then
                                format := bin;
                            elsif ptr(src_i) = 'o' then
                                format := oct;
                            end if;
                            src_i := src_i + 1;
                            if src_i = src_tail_begin then
                                exit;
                            end if;
                        elsif ptr(src_i) = '@' then
                            insert_var := false;
                            src_i := src_i + 1;
                            if src_i = src_tail_begin then
                                exit;
                            end if;
                            if ptr(src_i) = 'c' then
                                insert_call_stack_label := true;
                            elsif ptr(src_i) = 'f' then
                                insert_call_stack_file := true;
                            elsif ptr(src_i) = 'l' then
                                insert_call_stack_line_number := true;
                            else
                                assert (false)
                                report lf & "error: wrong substitution format in {...} brackets " & stm_text_crop(input_txt)
                                severity failure;
                            end if;
                            src_i := src_i + 1;
                            if src_i = src_tail_begin then
                                exit;
                            end if;
                            previous_level := c2int(ptr(src_i));
                            src_i := src_i + 1;
                            if src_i = src_tail_begin then
                                exit;
                            end if;
                        else
                            assert (false)
                            report lf & "error: wrong substitution format in {...} brackets " & stm_text_crop(input_txt)
                            severity failure;
                        end if;
                    end if;
                end loop;
            end if;
            if ptr(src_i) = '}' then
                src_i := src_i + 1;
            else
                assert (false)
                report lf & "error: missing closing } bracket " & stm_text_crop(input_txt)
                severity failure;
            end if;

            if insert_var then
                while src_tail_i <= c_stm_text_len loop
                    if ptr(src_tail_i) = '$' then
                        exit;
                    else
                        src_tail_i := src_tail_i + 1;
                    end if;
                end loop;
                assert ptr(src_tail_i) = '$'
                report lf & "error: missing variable for substitution bracket " & stm_text_crop(input_txt)
                severity failure;
                tmp_field := (others => nul);
                tmp_i := 1;
                tmp_field(tmp_i) := ptr(src_tail_i);
                src_tail_i := src_tail_i + 1;
                tmp_i := tmp_i + 1;
                -- parse to the next space
                while ptr(src_tail_i) /= ' ' and ptr(src_tail_i) /= nul loop
                    tmp_field(tmp_i) := ptr(src_tail_i);
                    src_tail_i := src_tail_i + 1;
                    tmp_i := tmp_i + 1;
                end loop;
                access_variable(var_list, tmp_field, v1, valid);
                assert (valid = 1)
                report lf & "invalid variable found in stm_text_ptr: ignoring."
                severity warning;
                if valid = 1 then
                    dest_txt_str := ew_str_cat(dest_txt_str, ew_to_str(v1, format));
                    k := 1;
                    while dest_txt_str(k) /= nul loop
                        k := k + 1;
                    end loop;
                    dest_i := k;
                end if;
            elsif insert_call_stack_file then
                stack_called_file := stack_called_files(stack_ptr - previous_level)(1 to max_field_len);
                dest_txt_str := ew_str_cat(dest_txt_str, stack_called_file);
                k := 1;
                while dest_txt_str(k) /= nul loop
                    k := k + 1;
                end loop;
                dest_i := k;
            elsif insert_call_stack_line_number then
                stack_called_file_line_number := stack_called_file_line_numbers(stack_ptr - previous_level);
                dest_txt_str := ew_str_cat(dest_txt_str, ew_to_str(stack_called_file_line_number, dec));
                k := 1;
                while dest_txt_str(k) /= nul loop
                    k := k + 1;
                end loop;
                dest_i := k;
            elsif insert_call_stack_label then
                stack_called_label := stack_called_labels(stack_ptr - previous_level);
                dest_txt_str := ew_str_cat(dest_txt_str, stack_called_label, 2);
                k := 1;
                while dest_txt_str(k) /= nul loop
                    k := k + 1;
                end loop;
                dest_i := k;
            end if;
        end loop;
        assert false
        report lf & "error: txt_print_wvar ended abnormally " & stm_text_crop(input_txt)
        severity failure;
    end procedure;

    procedure test_inst_sequ(variable inst_sequ : in stim_line_ptr;
                             variable file_list : in file_def_ptr;
                             variable var_list : in var_field_ptr;
                             constant stm_value_width : in integer) is
        variable temp_text_field : text_field;
        variable inst_ptr : stim_line_ptr;
        variable v_p : unsigned(stm_value_width - 1 downto 0);
        variable valid : integer;
        variable line : integer; -- value of the file_line
        variable file_name : text_line;
        variable tmp_file_list : file_def_ptr := file_list;
    begin
        inst_ptr := inst_sequ;
        -- go through all the instructions
        while inst_ptr.next_rec /= null loop
            line := inst_ptr.file_line;
            get_instruction_file_name(tmp_file_list, inst_ptr.file_idx, file_name);
            temp_text_field := inst_ptr.inst_field_1;
            if temp_text_field(1) /= nul then
                if is_digit(temp_text_field(1)) then
                    null;
                else
                    access_variable(var_list, temp_text_field, v_p, valid);
                    assert valid = 1
                    report lf & "error: first variable on stimulus line " & (integer'image(line)) & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            temp_text_field := inst_ptr.inst_field_2;
            if temp_text_field(1) /= nul then
                if is_digit(temp_text_field(1)) then
                    null;
                else
                    access_variable(var_list, temp_text_field, v_p, valid);
                    assert valid = 1
                    report lf & "error: second variable on stimulus line " & (integer'image(line)) & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            temp_text_field := inst_ptr.inst_field_3;
            if temp_text_field(1) /= nul then
                if is_digit(temp_text_field(1)) then
                    null;
                else
                    access_variable(var_list, temp_text_field, v_p, valid);
                    assert valid = 1
                    report lf & "error: third variable on stimulus line " & (integer'image(line)) & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            temp_text_field := inst_ptr.inst_field_4;
            if temp_text_field(1) /= nul then
                if is_digit(temp_text_field(1)) then
                    null;
                else
                    access_variable(var_list, temp_text_field, v_p, valid);
                    assert valid = 1
                    report lf & "error: forth variable on stimulus line " & (integer'image(line)) & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            temp_text_field := inst_ptr.inst_field_5;
            if temp_text_field(1) /= nul then
                if is_digit(temp_text_field(1)) then
                    null;
                else
                    access_variable(var_list, temp_text_field, v_p, valid);
                    assert valid = 1
                    report lf & "error: fifth variable on stimulus line " & (integer'image(line)) & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            temp_text_field := inst_ptr.inst_field_6;
            if temp_text_field(1) /= nul then
                if is_digit(temp_text_field(1)) then
                    null;
                else
                    access_variable(var_list, temp_text_field, v_p, valid);
                    assert valid = 1
                    report lf & "error: sixth variable on stimulus line " & (integer'image(line)) & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            inst_ptr := inst_ptr.next_rec;
        end loop;
    end procedure;

    procedure tokenize_line(variable text_line : in text_line;
                            variable otoken1 : out text_field;
                            variable otoken2 : out text_field;
                            variable otoken3 : out text_field;
                            variable otoken4 : out text_field;
                            variable otoken5 : out text_field;
                            variable otoken6 : out text_field;
                            variable otoken7 : out text_field;
                            variable txt_ptr : out stm_text_ptr;
                            variable txt_enclosing_quote : out character;
                            variable ovalid : out integer) is
        variable token_index : integer := 0;
        variable current_token : text_field;
        variable token_number : integer := 0;
        variable c : string(1 to 2);
        variable comment_found : integer := 0;
        variable txt_found : integer := 0;
        variable j : integer;
        variable txt_ptr_tmp : stm_text_ptr;
        variable txt_str : stm_text;
        variable token1 : text_field;
        variable token2 : text_field;
        variable token3 : text_field;
        variable token4 : text_field;
        variable token5 : text_field;
        variable token6 : text_field;
        variable token7 : text_field;
        variable token8 : text_field;
        variable token9 : text_field;
        variable valid : integer := 0;
        constant SINGLE_QUOTE : character := character'val(39);
        constant DOUBLE_QUOTE : character := character'val(34);

    begin
        -- null outputs
        token1 := (others => nul);
        token2 := (others => nul);
        token3 := (others => nul);
        token4 := (others => nul);
        token5 := (others => nul);
        token6 := (others => nul);
        token7 := (others => nul);
        token8 := (others => nul);
        token9 := (others => nul);
        txt_ptr := null;
        txt_ptr_tmp := null;
        valid := 0;
        txt_found := 0;
        j := 1;
        txt_str := (others => nul);
        -- loop for max number of char
        for i in 1 to text_line'high loop
            -- collect for comment test ** assumed no line will be max 256
            c(1) := text_line(i);
            c(2) := text_line(i + 1); -- or this line will blow up
            if c = "--" then
                comment_found := 1;
                exit;
            end if;
            -- if is begin text char
            if txt_found = 0 and (c(1) = DOUBLE_QUOTE or c(1) = SINGLE_QUOTE) then
                txt_found := 1;
                txt_enclosing_quote := c(1);
                txt_ptr_tmp := new stm_text;
                next;
            end if;
            -- if we have found a txt string
            if txt_found = 1 and text_line(i) /= nul then
                -- if string too long, prevent tool hang, truncate and notify
                if j > c_stm_text_len then
                    print("tokenize_line: truncated txt line, it was larger than c_stm_text_len");
                    exit;
                end if;
                -- till the very end of text_line
                if text_line(i) /= nul then
                    txt_str(j) := text_line(i);
                    txt_ptr_copy(txt_ptr_tmp, txt_ptr, txt_str);
                    j := j + 1;
                else
                    exit;
                end if;
            -- if is a character store in the right token
            elsif is_space(text_line(i)) = false and text_line(i) /= nul then
                token_index := token_index + 1;
                current_token(token_index) := text_line(i);
            -- else is a space, deal with pointers
            elsif is_space(text_line(i + 1)) = false and text_line(i + 1) /= nul then
                case token_number is
                    when 0 =>
                        if token_index /= 0 then
                            token1 := current_token;
                            current_token := (others => nul);
                            token_number := 1;
                            valid := 1;
                            token_index := 0;
                        end if;
                    when 1 =>
                        token2 := current_token;
                        current_token := (others => nul);
                        token_number := 2;
                        valid := 2;
                        token_index := 0;
                    when 2 =>
                        token3 := current_token;
                        current_token := (others => nul);
                        token_number := 3;
                        valid := 3;
                        token_index := 0;
                    when 3 =>
                        token4 := current_token;
                        current_token := (others => nul);
                        token_number := 4;
                        valid := 4;
                        token_index := 0;
                    when 4 =>
                        token5 := current_token;
                        current_token := (others => nul);
                        token_number := 5;
                        valid := 5;
                        token_index := 0;
                    when 5 =>
                        token6 := current_token;
                        current_token := (others => nul);
                        token_number := 6;
                        valid := 6;
                        token_index := 0;
                    when 6 =>
                        token7 := current_token;
                        current_token := (others => nul);
                        token_number := 7;
                        valid := 7;
                        token_index := 0;
                    when 7 =>
                        token8 := current_token;
                        current_token := (others => nul);
                        token_number := 8;
                        valid := 8;
                        token_index := 0;
                    when 8 =>
                        token9 := current_token;
                        current_token := (others => nul);
                        token_number := 9;
                        valid := 9;
                        token_index := 0;
                    when 9 =>
                    when others =>
                        null;
                end case;
            end if;
            -- break from loop if is null
            if text_line(i) = nul then
                if token_index /= 0 then
                    case token_number is
                        when 0 =>
                            token1 := current_token;
                            valid := 1;
                        when 1 =>
                            token2 := current_token;
                            valid := 2;
                        when 2 =>
                            token3 := current_token;
                            valid := 3;
                        when 3 =>
                            token4 := current_token;
                            valid := 4;
                        when 4 =>
                            token5 := current_token;
                            valid := 5;
                        when 5 =>
                            token6 := current_token;
                            valid := 6;
                        when 6 =>
                            token7 := current_token;
                            valid := 7;
                        when 7 =>
                            token8 := current_token;
                            valid := 8;
                        when 8 =>
                            token9 := current_token;
                            valid := 9;
                        when others =>
                            null;
                    end case;
                end if;
                exit;
            end if;
        end loop;
        -- did we find a comment and there is a token
        if comment_found = 1 then
            if token_index /= 0 then
                case token_number is
                    when 0 =>
                        token1 := current_token;
                        valid := 1;
                    when 1 =>
                        token2 := current_token;
                        valid := 2;
                    when 2 =>
                        token3 := current_token;
                        valid := 3;
                    when 3 =>
                        token4 := current_token;
                        valid := 4;
                    when 4 =>
                        token5 := current_token;
                        valid := 5;
                    when 5 =>
                        token6 := current_token;
                        valid := 6;
                    when 6 =>
                        token7 := current_token;
                        valid := 7;
                    when 7 =>
                        token8 := current_token;
                        valid := 8;
                    when 8 =>
                        token9 := current_token;
                        valid := 9;
                    when others =>
                        null;
                end case;
            end if;
        end if;
        token_merge_words(token1, token2, token3, token4, token5, token6, token7, token8, token9, valid,
                          otoken1, otoken2, otoken3, otoken4, otoken5, otoken6, otoken7, ovalid);
    end procedure;

    procedure txt_print_wvar(variable var_list : in var_field_ptr;
                             variable ptr : in stm_text_ptr;
                             variable txt_enclosing_quote : in character;
                             variable stack_ptr : integer;
                             variable stack_called_files : stack_text_line_array;
                             variable stack_called_file_line_numbers : stack_numbers_array;
                             variable stack_called_labels : stack_text_field_array;
                             constant stm_value_width : in integer) is
        variable stm_text_substituded : stm_text;
    begin
        stm_text_substitude_wvar(var_list, ptr, txt_enclosing_quote, stack_ptr, stack_called_files, stack_called_file_line_numbers, stack_called_labels, stm_text_substituded, stm_value_width);
        print(stm_text_substituded);
    end procedure;

    procedure update_variable(variable var_list : in var_field_ptr;
                              variable index_stm_value : in unsigned;
                              variable value : in unsigned;
                              variable valid : out integer) is
        variable index : integer;
    begin
        index := to_integer(index_stm_value(30 downto 0));
        update_variable(var_list, index, value, valid);
    end procedure;

    procedure update_variable(variable var_list : in var_field_ptr;
                              variable index_stm_value : in unsigned;
                              variable integer_value : in integer;
                              variable valid : out integer) is
        variable stm_value : unsigned(index_stm_value'length - 1 downto 0) := to_unsigned(0, index_stm_value'length);
    begin
        stm_value := to_unsigned(integer_value, index_stm_value'length);
        update_variable(var_list, index_stm_value, stm_value, valid);
    end procedure;

    procedure update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable value : in unsigned;
                              variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if (ptr.var_index = index and ptr.var_stm_type /= STM_CONST_VALUE_TYPE) then
                ptr.var_value := value;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        -- check the current one
        if ptr.var_index = index and ptr.var_stm_type /= STM_CONST_VALUE_TYPE then
            ptr.var_value := value;
            valid := 1;
        end if;
    end procedure;

    procedure update_variable(variable var_list : in var_field_ptr;
                              variable index_stm_value : in unsigned;
                              variable var_stm_text : in stm_text_ptr;
                              variable valid : out integer) is
        variable index : integer;
    begin
        index := to_integer(index_stm_value(30 downto 0));
        update_variable(var_list, index, var_stm_text, valid);
    end procedure;

    procedure update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable var_stm_text : in stm_text_ptr;
                              variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index then
                ptr.var_stm_text := var_stm_text;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if ptr.var_index = index then
            ptr.var_stm_text := var_stm_text;
            valid := 1;
        end if;
    end procedure;

    procedure update_variable(variable var_list : in var_field_ptr;
                              variable index_stm_value : in unsigned;
                              variable stm_array : in t_stm_array_ptr;
                              variable valid : out integer) is
        variable index : integer;
    begin
        index := to_integer(index_stm_value(30 downto 0));
        update_variable(var_list, index, stm_array, valid);
    end procedure;

    procedure update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable stm_array : in t_stm_array_ptr;
                              variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index and ptr.var_stm_type /= STM_CONST_VALUE_TYPE then
                ptr.var_stm_array := stm_array;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        -- check the current one
        if ptr.var_index = index and ptr.var_stm_type /= STM_CONST_VALUE_TYPE then
            ptr.var_stm_array := stm_array;
            valid := 1;
        end if;
    end procedure;

    procedure update_variable(variable var_list : in var_field_ptr;
                              variable index_stm_value : in unsigned;
                              variable stm_lines : in t_stm_lines_ptr;
                              variable valid : out integer) is
        variable index : integer;
    begin
        index := to_integer(index_stm_value(30 downto 0));
        update_variable(var_list, index, stm_lines, valid);
    end procedure;

    procedure update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable stm_lines : in t_stm_lines_ptr;
                              variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if (ptr.var_index = index) then
                ptr.var_stm_lines := stm_lines;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if ptr.var_index = index then
            ptr.var_stm_lines := stm_lines;
            valid := 1;
        end if;
    end procedure;

end package body;
