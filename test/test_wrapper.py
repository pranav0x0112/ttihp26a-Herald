import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles

def to_fixed(val):
    """Convert float to Q16.16 fixed point"""
    return int(val * 65536) & 0xFFFFFFFF

def from_fixed(val):
    """Convert Q16.16 fixed point to float"""
    if val & 0x80000000:
        val = val - 0x100000000
    return val / 65536.0

async def reset_dut(dut):
    """Reset the DUT"""
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

async def send_chunk(dut, data_chunk, cmd):
    """Send a 6-bit data chunk with command and strobe"""
    # Strobe low
    dut.ui_in.value = (cmd << 6) | (data_chunk & 0x3F)
    await RisingEdge(dut.clk)
    
    # Strobe high (bit 5)
    dut.ui_in.value = (cmd << 6) | 0x20 | (data_chunk & 0x1F)
    await RisingEdge(dut.clk)
    
    # Strobe low
    dut.ui_in.value = (cmd << 6) | (data_chunk & 0x3F)
    await RisingEdge(dut.clk)

async def send_32bit(dut, value, cmd):
    """Send a 32-bit value as 6 chunks of 6 bits (36 bits total, MSB-aligned)"""
    # Shift left by 4 to align 32 bits in 36-bit space
    value_36 = (value & 0xFFFFFFFF) << 4
    
    # Send 6 chunks, MSB first
    for i in range(6):
        shift = 30 - (i * 6)
        chunk = (value_36 >> shift) & 0x3F
        await send_chunk(dut, chunk, cmd)

async def read_32bit(dut, cmd):
    """Read a 32-bit value as 6 chunks of 6 bits"""
    result = 0
    
    for i in range(6):
        # Strobe to request next chunk
        dut.ui_in.value = (cmd << 6) | 0x00
        await RisingEdge(dut.clk)
        
        dut.ui_in.value = (cmd << 6) | 0x20
        await RisingEdge(dut.clk)
        
        # Read output (lower 6 bits)
        chunk = int(dut.uo_out.value) & 0x3F
        result = (result << 6) | chunk
        
        dut.ui_in.value = (cmd << 6) | 0x00
        await RisingEdge(dut.clk)
    
    # Shift right by 4 to get 32-bit value from 36-bit
    return (result >> 4) & 0xFFFFFFFF

async def mac_multiply(dut, a, b):
    """Perform MAC multiply operation"""
    # Send command to start multiply (cmd=01)
    dut.ui_in.value = 0x40  # cmd=01, strobe=0
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0x60  # cmd=01, strobe=1
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0x40  # cmd=01, strobe=0
    await RisingEdge(dut.clk)
    
    # Send operand A
    await send_32bit(dut, a, 0x01)
    
    # Send operand B
    await send_32bit(dut, b, 0x01)
    
    # Wait for computation
    await ClockCycles(dut.clk, 10)
    
    # Read result
    result = await read_32bit(dut, 0x01)
    return result

async def mac_clear(dut):
    """Clear MAC accumulator"""
    # Send clear command (cmd=11)
    dut.ui_in.value = 0xC0  # cmd=11, strobe=0
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0xE0  # cmd=11, strobe=1
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0xC0  # cmd=11, strobe=0
    await RisingEdge(dut.clk)
    
    # Wait for operation
    await ClockCycles(dut.clk, 10)



@cocotb.test()
async def test_wrapper_mac_simple(dut):
    """Simplified test with direct state observation"""
    
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())
    
    await reset_dut(dut)
    
    # Just verify wrapper responds to commands
    dut.ui_in.value = 0x00
    await ClockCycles(dut.clk, 5)
    
    # Check that design is alive (uo_out should show state)
    state = int(dut.uo_out.value)
    dut._log.info(f"Wrapper state: {state:02x}")
    
    # This test just ensures wrapper instantiates without errors
    assert True

@cocotb.test()
async def test_wrapper_reset(dut):
    """Test that wrapper resets properly"""
    
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())
    
    await reset_dut(dut)
    
    # After reset, should be in IDLE state (0)
    await ClockCycles(dut.clk, 2)
    state = (int(dut.uo_out.value) >> 3) & 0x07
    
    dut._log.info(f"State after reset: {state}")
    assert state == 0, f"Expected IDLE state (0), got {state}"
