// Circular buffer for audio samples, clears when full.
// If the buffer is cleared, either a larger buffer is needed or output is slower than input.

// Operating principles:
// * remove_position is the next available audio sample, if any
// * insert_position is the next empty buffer location
// * remaining is the distance between insert and remove
//     * insert is always ahead of remove -- if remove > insert, a position has wrapped around from BUFFER_SIZE and an alternate calculation is used
// * if the buffer is completely filled, insert and remove become equal and the remaining count drops from BUFFER_SIZE-1 to 0.
module buffer 
#(
    parameter BUFFER_SIZE = 128,
    parameter BIT_WIDTH = 16,
    parameter CHANNELS = 2
)
(
    input logic clk_audio,
    input logic clk_packet,
    input logic [BIT_WIDTH-1:0] audio_in [CHANNELS-1:0],
    output logic [BIT_WIDTH-1:0] audio_out [CHANNELS-1:0],
    output logic [$clog2(BUFFER_SIZE)-1:0] remaining
);

localparam BUFFER_WIDTH = $clog2(BUFFER_SIZE);

const bit [BUFFER_WIDTH-1:0] BUFFER_END = 2 ** BUFFER_WIDTH == BUFFER_SIZE ? ~(BUFFER_WIDTH'(0)) : BUFFER_WIDTH'(BUFFER_SIZE) - 1'b1;

logic [BUFFER_WIDTH-1:0] insert_position = 0;
logic [BUFFER_WIDTH-1:0] remove_position = 0;

assign remaining = insert_position >= remove_position ? (insert_position - remove_position) : (BUFFER_END - remove_position + insert_position);

logic [19:0] audio_buffer [BUFFER_SIZE-1:0] [CHANNELS-1:0];

assign audio_out = audio_buffer[remove_position];

always @(posedge clk_audio)
begin
    // Insert
    audio_buffer[insert_position] <= audio_in;
    insert_position <= insert_position == BUFFER_END ? BUFFER_WIDTH'(0) : insert_position + 1'd1;
end

always @(posedge clk_packet)
begin
    if (remaining > 1'd0) // Remove. Remaining constraint ensures that the remaining count does not wrap around from 0 to BUFFER_SIZE.
    begin
        remove_position <= remove_position == BUFFER_END ? BUFFER_WIDTH'(0) : remove_position + 1'd1;
    end else
    begin
        // clk_packet but no items left
    end
end

endmodule