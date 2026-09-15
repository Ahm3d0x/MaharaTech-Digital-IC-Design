$ErrorActionPreference = "Stop"
$root = "g:\modelsim-projects\maharathech"
$modelsim_bin = "G:\modelsim\modelsim_ase\win32aloem"
$env:PATH = "$modelsim_bin;$env:PATH"
$img_dir = "$root\docs\images"

if (!(Test-Path $img_dir)) {
    New-Item -ItemType Directory -Force -Path $img_dir | Out-Null
}

$simulations = @(
    @{
        Name = "Lab 1: XOR Gate"
        Dir = "$root\labs\xorgate"
        Files = @("xor_gate.v", "xor_gate_tb.v")
        Top = "xor_gate_tb"
        OutImg = "$img_dir\lab1_xorgate_wave.png"
        Title = "Lab 1: XOR Gate Simulation Waveform"
    },
    @{
        Name = "Lab 2: OR Gate"
        Dir = "$root\labs\orgate"
        Files = @("orgate.v", "orgate_tb_dut.v")
        Top = "orgate_tb"
        OutImg = "$img_dir\lab2_orgate_wave.png"
        Title = "Lab 2: OR Gate Simulation Waveform"
    },
    @{
        Name = "Lab 3: D Flip-Flop"
        Dir = "$root\labs\d-ff"
        Files = @("d-ff.v", "d_ff_tp.v")
        Top = "d_ff_tb"
        OutImg = "$img_dir\lab3_dff_wave.png"
        Title = "Lab 3: D Flip-Flop (Async Reset) Simulation Waveform"
    },
    @{
        Name = "Lab 4: Frequency Divider"
        Dir = "$root\labs\frequancy_devider"
        Files = @("frequancy_devider.v", "frequancy_devider_tb.v")
        Top = "frequancy_devider_tb"
        OutImg = "$img_dir\lab4_freq_divider_wave.png"
        Title = "Lab 4: Frequency Divider (/100) Simulation Waveform"
    },
    @{
        Name = "Lab 5: 7-Segment Decoder"
        Dir = "$root\labs\seven_segmant_decoder"
        Files = @("seven_segmant_decoder.v", "seven_segmant_decoder_tb.v")
        Top = "seven_segmant_decoder_tb"
        OutImg = "$img_dir\lab5_7segment_decoder_wave.png"
        Title = "Lab 5: 7-Segment Decoder Simulation Waveform"
    },
    @{
        Name = "Lab 6: Johnson Counter"
        Dir = "$root\labs\counter"
        Files = @("counter.v", "counter_tb.v")
        Top = "Johnson_counter_tb"
        OutImg = "$img_dir\lab6_johnson_counter_wave.png"
        Title = "Lab 6: Johnson Counter (4-bit) Simulation Waveform"
    },
    @{
        Name = "Lab 7: Counter 1-99"
        Dir = "$root\labs\counter_1-99"
        Files = @("counter.v", "counter_tb.v")
        Top = "counter_1_99_tb"
        OutImg = "$img_dir\lab7_counter_1_99_wave.png"
        Title = "Lab 7: BCD Decimal Counter (00-99) Simulation Waveform"
    },
    @{
        Name = "Lab 8: Counter Using States (FSM)"
        Dir = "$root\labs\counter_using_stat"
        Files = @("counter_using_stat.v", "counter_using_stat_tb.v")
        Top = "counter_using_stat_tb"
        OutImg = "$img_dir\lab8_counter_fsm_wave.png"
        Title = "Lab 8: State Machine Counter (FSM) Simulation Waveform"
    },
    @{
        Name = "Project 1: Full Adder"
        Dir = "$root\fulladder"
        Files = @("fulladder.v", "fulladder_tb.v")
        Top = "fulladder_tb"
        OutImg = "$img_dir\project1_fulladder_wave.png"
        Title = "Project 1: Hierarchical Full Adder Simulation Waveform"
    },
    @{
        Name = "Project 2: Keyboard Priority Encoder"
        Dir = "$root\keybord_encoder"
        Files = @("keybord_encoder.v", "keybord_encoder_tb.v")
        Top = "keybord_encoder_tb"
        OutImg = "$img_dir\project2_keybord_encoder_wave.png"
        Title = "Project 2: Keyboard Priority Encoder (9-to-4) Simulation Waveform"
    },
    @{
        Name = "Project 3: Keypad to 3 Room Displays"
        Dir = "$root\kepad_to_3display"
        Files = @("kepad_to_3display.v", "kepad_to_3display_tb.v")
        Top = "kepad_to_3display_tb"
        OutImg = "$img_dir\project3_keypad_to_3display_wave.png"
        Title = "Project 3: Keypad to 3 Room Displays Subsystem Waveform"
    },
    @{
        Name = "Project 4: Queue Management System"
        Dir = "$root\Queue Management System (FSM + Counter)"
        Files = @("Queue_Management_System.v", "rom_data.v", "seven_segmant_decoder.v", "Queue_Management_System_tb.v")
        Top = "Queue_Management_System_tb"
        OutImg = "$img_dir\project4_queue_management_wave.png"
        Title = "Project 4: Queue Management System Simulation Waveform"
    }
)

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " Running Automated ModelSim Simulation & Waveform Gen" -ForegroundColor Cyan
Write-Host " Total designs: $($simulations.Count)" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

foreach ($sim in $simulations) {
    Write-Host "`n>>> Processing: $($sim.Name)..." -ForegroundColor Yellow
    Push-Location $sim.Dir
    try {
        # 1. Prepare work library
        if (Test-Path "work") {
            Remove-Item -Recurse -Force "work"
        }
        & "$modelsim_bin\vlib.exe" work | Out-Null

        # 2. Compile
        Write-Host "   Compiling files: $($sim.Files -join ', ')..."
        & "$modelsim_bin\vlog.exe" -work work $sim.Files
        if ($LASTEXITCODE -ne 0) {
            throw "Compilation failed for $($sim.Name)"
        }

        # 3. Simulate and generate VCD
        Write-Host "   Simulating $($sim.Top)..."
        if (Test-Path "dump.vcd") {
            Remove-Item -Force "dump.vcd"
        }
        & "$modelsim_bin\vsim.exe" -c -do "vsim work.$($sim.Top); run -all; quit" | Out-Null
        if (!(Test-Path "dump.vcd")) {
            throw "dump.vcd was not generated for $($sim.Name)"
        }

        # 4. Render Waveform Image
        Write-Host "   Rendering Waveform -> $($sim.OutImg)..."
        py "$root\scripts\render_vcd.py" "dump.vcd" $sim.OutImg $sim.Title
        if ($LASTEXITCODE -ne 0) {
            throw "Rendering failed for $($sim.Name)"
        }

        Write-Host "   [SUCCESS] $($sim.Name)" -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

Write-Host "`n====================================================" -ForegroundColor Green
Write-Host " All 12 simulations completed and waveforms generated!" -ForegroundColor Green
Write-Host " Images saved in: $img_dir" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
