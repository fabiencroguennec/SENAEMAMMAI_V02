export const googleFonts = [
    { name: 'Inter', value: 'Inter, sans-serif' },
    { name: 'Roboto', value: 'Roboto, sans-serif' },
    { name: 'Open Sans', value: '"Open Sans", sans-serif' },
    { name: 'Lato', value: 'Lato, sans-serif' },
    { name: 'Montserrat', value: 'Montserrat, sans-serif' },
    { name: 'Poppins', value: 'Poppins, sans-serif' },
    { name: 'Playfair Display', value: '"Playfair Display", serif' },
    { name: 'Merriweather', value: 'Merriweather, serif' },
    { name: 'Lora', value: 'Lora, serif' },
    { name: 'Oswald', value: 'Oswald, sans-serif' },
    { name: 'Raleway', value: 'Raleway, sans-serif' },
    { name: 'Nunito', value: 'Nunito, sans-serif' },
    { name: 'Rubik', value: 'Rubik, sans-serif' },
    { name: 'Ubuntu', value: 'Ubuntu, sans-serif' },
    { name: 'Cinzel', value: 'Cinzel, serif' },
    { name: 'Cormorant Garamond', value: '"Cormorant Garamond", serif' }
]

export const getGoogleFontUrl = (fontFamily: string) => {
    if (!fontFamily) return ''
    // Extract name "Roboto" from "Roboto, sans-serif"
    const name = fontFamily.split(',')[0].replace(/['"]/g, '').trim()
    return `https://fonts.googleapis.com/css2?family=${name.replace(/ /g, '+')}:wght@100;300;400;500;700;900&display=swap`
}
