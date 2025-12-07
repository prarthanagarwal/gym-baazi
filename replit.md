# Gym-Baazi Workout Tracker

## Overview

Gym-Baazi is a modern workout tracking web application designed for PPL (Push/Pull/Legs) training splits. The app provides automated workout scheduling based on day of week, exercise library with video demonstrations, workout session tracking with set-by-set logging, and comprehensive workout history. Built with React and TypeScript on the frontend with an Express backend, it features a mobile-first design optimized for iPhone usage with haptic feedback and smooth animations.

## User Preferences

Preferred communication style: Simple, everyday language.

## System Architecture

### Frontend Architecture

**Framework**: React 18 with TypeScript, using Vite as the build tool and development server.

**Routing**: Wouter for lightweight client-side routing between Home, Workout Session, Exercise Library, and History pages.

**State Management**: 
- React Context API for shared workout timer state (`WorkoutProvider`)
- TanStack Query (React Query) for server state management and API caching
- Local component state with React hooks

**UI Components**: 
- Radix UI primitives for accessible, unstyled components (dialogs, popovers, dropdowns, etc.)
- Custom components built on Radix with Tailwind CSS styling
- shadcn/ui component system configuration (New York style variant)
- Framer Motion for animations and transitions

**Styling**:
- Tailwind CSS with custom design tokens and CSS variables
- Dark mode by default with custom gradient styles for workout types (Push/Pull/Legs/Rest)
- Mobile-first responsive design with safe area considerations
- Custom fonts: Space Grotesk for headings, DM Sans for body text

**Key Design Patterns**:
- Component composition with slot-based patterns (Radix primitives)
- Separation of concerns: presentation components, API hooks, and business logic
- Custom hooks for reusable logic (haptics, workout state, mobile detection)
- Query invalidation patterns for optimistic updates

### Backend Architecture

**Framework**: Express.js with TypeScript running on Node.js.

**API Design**: RESTful API with resource-based endpoints for workout logs, exercise sets, and user settings.

**Request/Response Handling**:
- JSON body parsing with raw body buffer for webhook support
- Structured error handling with appropriate HTTP status codes
- Request logging middleware tracking duration and response details

**Key Endpoints**:
- `/api/workout-logs` - CRUD operations for workout sessions
- `/api/exercise-sets` - Manage individual exercise set data
- `/api/user-settings` - User preferences and configuration

**Server Structure**:
- Route registration pattern separating route definitions from server setup
- Storage abstraction layer (`IStorage` interface) for database operations
- Development vs production mode handling with different static file serving

### Data Storage

**Database**: PostgreSQL accessed through Neon serverless driver with WebSocket support.

**ORM**: Drizzle ORM for type-safe database queries and schema management.

**Schema Design**:
- `users` table for authentication (username/password)
- `workoutLogs` table tracking daily workout sessions with type (PUSH/PULL/LEGS/REST) and completion status
- `exerciseSets` table with foreign key to workoutLogs, storing reps, weight, and completion per set
- `userSettings` table for reminder preferences and workout rotation state

**Data Validation**: Zod schemas derived from Drizzle schemas for runtime validation.

**Migration Strategy**: Drizzle Kit for schema migrations with PostgreSQL dialect.

### External Dependencies

**MuscleWiki API**: Referenced in documentation for exercise video demonstrations and exercise data. The application maps internal exercise IDs to MuscleWiki exercise IDs for fetching demonstrations.

**ExerciseDB API**: Alternative/backup exercise database referenced in the codebase (uses RapidAPI format with exercise IDs like "0025" for exercises).

**Neon Database**: Serverless PostgreSQL database provider with WebSocket connection pooling.

**Replit Platform**: 
- Development environment with custom Vite plugins for runtime error handling
- Deployment infrastructure with meta image updates for OpenGraph
- Dev banner and cartographer plugins for development mode

**CDN Dependencies**:
- Google Fonts API for Space Grotesk and DM Sans font families
- Preconnected to fonts.googleapis.com and fonts.gstatic.com

**Third-party Services**:
- Lucide React for icon components
- date-fns for date manipulation and formatting
- Framer Motion for animation library
- Radix UI component primitives (26+ component packages)