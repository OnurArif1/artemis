# Artemis Web

A modern Vue.js 3 web application for the Artemis project.

## Features

- **Vue.js 3** with Composition API
- **Vue Router** for client-side routing
- **Pinia** for state management
- **Axios** for HTTP requests
- **Vite** for fast development and building
- **Modern UI** with responsive design
- **JWT Authentication** integration
- **Protected Routes** with authentication guards

## Project Structure

```
web/
├── src/
│   ├── components/          # Reusable Vue components
│   ├── views/              # Page components
│   │   ├── Home.vue        # Landing page
│   │   ├── Login.vue       # Login/Register page
│   │   ├── Dashboard.vue   # User dashboard
│   │   └── Profile.vue     # User profile page
│   ├── stores/             # Pinia stores
│   │   └── auth.js         # Authentication store
│   ├── services/           # API services
│   │   └── authService.js  # Authentication service
│   ├── router/             # Vue Router configuration
│   │   └── index.js        # Route definitions
│   ├── assets/             # Static assets
│   │   └── css/            # Global styles
│   ├── App.vue             # Root component
│   └── main.js             # Application entry point
├── index.html              # HTML template
├── vite.config.js          # Vite configuration
└── package.json            # Dependencies and scripts
```

## Getting Started

### Prerequisites

- Node.js (v16 or higher)
- npm or yarn

### Installation

1. Install dependencies:
```bash
npm install
```

2. Start development server:
```bash
npm run dev
```

3. Build for production:
```bash
npm run build
```

4. Preview production build:
```bash
npm run preview
```

## Configuration

The application is configured to work with the Artemis backend services:

- **API Gateway**: `http://localhost:5000`
- **Identity Server**: `http://localhost:5001`

These URLs can be modified in `vite.config.js` and `src/services/authService.js`.

## Authentication Flow

1. User logs in through the Login page
2. Credentials are sent to the Identity Server
3. JWT tokens are received and stored
4. Tokens are automatically included in API requests
5. Token refresh is handled automatically
6. Protected routes require authentication

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run serve` - Alias for preview

## Technologies Used

- **Vue.js 3** - Progressive JavaScript framework
- **Vue Router 4** - Official router for Vue.js
- **Pinia** - Vue state management library
- **Axios** - HTTP client for API requests
- **Vite** - Next generation web tooling
- **Sass** - CSS preprocessor

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)
