"""
Sprite Layout:
- Total sprites: 53 (index 0-52)
- Each sprite: 11×16 pixels (176 pixels)
- Indices 0-51: Standard deck (4 suits, 13 ranks)
- Index 52: Card back
    
Color Encoding (Bits: [R,G,B]):
0b000 = Black
0b111 = White
0b100 = Red
    
Card Design:
- Back: Checkerboard
- Front: White background with bordered edge, rank in top half, suit letter in bottom half
- Spades/Clubs: Black on white
- Hearts/Diamonds: Red on white
"""

import os

def generate_card_sprite(suit, rank):
    """Generate a single card sprite based on suit and rank.
    Args:
        suit (int):  0=Spades, 1=Hearts, 2=Clubs, 3=Diamonds
        rank (int): 0-12 (A, 2-10, J, Q, K)
    
    Returns:
        list: 176 3-bit color values representing the sprite
    """
    sprite = [[7] * 11 for _ in range(16)]  # Start with white (111) background
    
    rank_char = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'][rank]
    suit_char = ['S', 'H', 'C', 'D'][suit]
    suit_color = [0, 4, 0, 4][suit]
    
    # Draw border
    for col in range(11):
        sprite[0][col] = suit_color
        sprite[15][col] = suit_color
    for row in range(16):
        sprite[row][0] = suit_color
        sprite[row][10] = suit_color
    
    # Draw rank in top half (rows 2-7, centered)
    if rank == 9:  # "10" is special case
        draw_alphnum(sprite, 2, 1, '1', suit_color)
        draw_alphnum(sprite, 2, 5, '0', suit_color)
    else:
        draw_alphnum(sprite, 2, 3, rank_char, suit_color)
    
    # Draw suit letter in bottom half (rows 9-13)
    draw_alphnum(sprite, 9, 3, suit_char, suit_color)
    
    # Convert 2D array to flat list
    return [cell for row in sprite for cell in row]

def draw_alphnum(sprite, orig_x, orig_y, char, color):
    """Draw a large 5×5 digit/letter on the card sprite.
    Args:
        sprite (list): 2D list of the card pixels
        orig_x (int): Starting row for drawing (orig_x and orig_y represent top-left corner of the 5x5 pattern)
        orig_y (int): Starting column for drawing
        char (str): Character to draw (A, 2-10, J, Q, K, S, H, C, D)
        color (int): Color value to use for drawing (0 or 4)
    """
    patterns = {
        'A': [[0,1,1,1,0],
              [1,0,0,0,1],
              [1,1,1,1,1],
              [1,0,0,0,1],
              [1,0,0,0,1]],
        '2': [[1,1,1,0,0],
              [0,0,0,1,0],
              [0,1,1,0,0],
              [1,0,0,0,0],
              [1,1,1,1,0]],
        '3': [[1,1,1,0,0],
              [0,0,0,1,0],
              [1,1,1,0,0],
              [0,0,0,1,0],
              [1,1,1,0,0]],
        '4': [[1,0,0,1,0],
              [1,0,0,1,0],
              [1,1,1,1,1],
              [0,0,0,1,0],
              [0,0,0,1,0]],
        '5': [[1,1,1,1,0],
              [1,0,0,0,0],
              [1,1,1,1,0],
              [0,0,0,1,0],
              [1,1,1,0,0]],
        '6': [[0,1,1,0,0],
              [1,0,0,0,0],
              [1,1,1,0,0],
              [1,0,0,1,0],
              [0,1,1,0,0]],
        '7': [[1,1,1,1,0],
              [0,0,0,1,0],
              [0,0,1,0,0],
              [0,1,0,0,0],
              [1,0,0,0,0]],
        '8': [[0,1,1,0,0],
              [1,0,0,1,0],
              [0,1,1,0,0],
              [1,0,0,1,0],
              [0,1,1,0,0]],
        '9': [[0,1,1,0,0],
              [1,0,0,1,0],
              [0,1,1,1,0],
              [0,0,0,1,0],
              [0,1,1,0,0]],
        '1': [[0,1,0,0,0],
              [1,1,0,0,0],
              [0,1,0,0,0],
              [0,1,0,0,0],
              [1,1,1,0,0]],
        '0': [[0,1,1,0,0],
              [1,0,0,1,0],
              [1,0,0,1,0],
              [1,0,0,1,0],
              [0,1,1,0,0]],
        'J': [[1,1,1,1,0],
              [0,0,1,0,0],
              [0,0,1,0,0],
              [1,0,1,0,0],
              [0,1,1,0,0]],
        'Q': [[0,1,1,0,0],
              [1,0,0,1,0],
              [1,0,1,1,0],
              [0,1,1,1,0],
              [0,0,0,0,1]],
        'K': [[1,0,0,1,0],
              [1,0,1,0,0],
              [1,1,0,0,0],
              [1,0,1,0,0],
              [1,0,0,1,0]],
        'S': [[0,1,1,1,1],
              [1,0,0,0,0],
              [0,1,1,1,0],
              [0,0,0,0,1],
              [1,1,1,1,0]],
        'H': [[1,0,0,0,1],
              [1,0,0,0,1],
              [1,1,1,1,1],
              [1,0,0,0,1],
              [1,0,0,0,1]],
        'C': [[0,1,1,1,0],
              [1,0,0,0,0],
              [1,0,0,0,0],
              [1,0,0,0,0],
              [0,1,1,1,0]],
        'D': [[1,1,1,1,0],
              [1,0,0,0,1],
              [1,0,0,0,1],
              [1,0,0,0,1],
              [1,1,1,1,0]],
        
    }
    
    pattern = patterns.get(char, [[1]*5 for _ in range(5)])
    
    for row_idx, row in enumerate(pattern):
        for col_idx, pixel in enumerate(row):
            if orig_x + row_idx < 16 and orig_y + col_idx < 11:
                if pixel:
                    sprite[orig_x + row_idx][orig_y + col_idx] = color

def generate_all_sprites():
    """Generate all 53 card sprites."""
    sprites = []
    
    for rank in range(13):
        for suit in range(4):
                sprites.append(generate_card_sprite(suit, rank))
    
    # card back (index 52)
    for row in range(16):
        for col in range(11):
            if (row + col) % 2 == 0:
                pixel = 7
            else:
                pixel = 0
            sprites.append(pixel)
    
    return sprites

def write_pix_file(sprites):
    """
    Write all sprites to pix.txt in binary format.
    
    Args:
        sprites (list): List of sprite pixel arrays
    """
    output_dir = "pix_mem"
    os.makedirs(output_dir, exist_ok=True)
    
    values = []
    
    for sprite in sprites:
        for pixel in sprite:
            values.append(f"{pixel:03b}")
    
    # Fill remaining memory with zeros (unused sprites)
    total_pixels = len(values)
    remaining = 16384 - total_pixels
    values.extend(["000"] * remaining)
    
    with open(os.path.join(output_dir, "pix.txt"), "w") as file:
        file.write("\n".join(values))

if __name__ == "__main__":
    sprites = generate_all_sprites()
    write_pix_file(sprites)
