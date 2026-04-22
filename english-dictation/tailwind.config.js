/** @type {import('tailwindcss').Config} */
module.exports = {
  // NOTE: Update this to include the paths to all of your component files.
  content: ["./app/**/*.{js,jsx,ts,tsx}", "./components/**/*.{js,jsx,ts,tsx}"],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        darkblue: {
          50: '#f0f5fa',
          100: '#e1ecf4',
          200: '#c3d8e9',
          300: '#95bbd8',
          400: '#6199c2',
          500: '#3f7eab',
          600: '#2d658f',
          700: '#255174',
          800: '#224560',
          900: '#1a3247',
          950: '#0d1d2b',
        }
      },
      keyframes: {
        shake: {
          '10%, 90%': { transform: 'translateX(-1px)' },
          '20%, 80%': { transform: 'translateX(2px)' },
          '30%, 50%, 70%': { transform: 'translateX(-4px)' },
          '40%, 60%': { transform: 'translateX(4px)' },
        },
        flashSuccess: {
          '0%': { backgroundColor: 'rgba(34, 197, 94, 0.4)' },
          '100%': { backgroundColor: 'transparent' },
        },
        flashError: {
          '0%': { backgroundColor: 'rgba(239, 68, 68, 0.4)' },
          '100%': { backgroundColor: 'transparent' },
        }
      },
      animation: {
        shake: 'shake 0.5s cubic-bezier(.36,.07,.19,.97) both',
        'flash-success': 'flashSuccess 1s ease-out',
        'flash-error': 'flashError 1s ease-out',
      }
    },
  },
  plugins: [],
}