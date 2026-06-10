# GEMINI Code Companion: AuroraGov

This document provides a comprehensive overview of the AuroraGov project, designed to assist developers in understanding, running, and contributing to the codebase.

## Project Overview

AuroraGov is a digital governance platform built with Elixir and the Phoenix framework, structured as an umbrella application. It leverages Collective Intelligence to power its features. The project follows a CQRS (Command Query Responsibility Segregation) and Event Sourcing architectural pattern, using the `commanded` library.

The umbrella project consists of two main applications:

*   `aurora_gov`: The core application containing the business logic, domain models, commands, events, and persistence layer. It handles all non-web aspects of the platform.
*   `aurora_gov_web`: The web interface for the AuroraGov platform, built with the Phoenix framework. It provides the user interface and handles web-related concerns.

## Building and Running

### Prerequisites

*   Elixir
*   Docker

### Setup and Execution

1.  **Install Dependencies:**
    ```bash
    mix deps.get
    ```

2.  **Start the PostgreSQL Database:**
    A Docker container is used for the database.
    ```bash
    docker run --env=POSTGRES_PASSWORD=aurora_gov -p 4500:5432 --name=aurora-gov -d postgres:latest
    ```

3.  **Set up the Database and Applications:**
    This command runs the `setup` alias in all child applications, which includes creating the event store, running migrations, and seeding data.
    ```bash
    mix setup
    ```

4.  **Start the Phoenix Server:**
    ```bash
    iex -S mix phx.server
    ```

5.  **Access the Application:**
    Visit [`http://localhost:4000`](http://localhost:4000) in your browser.

## Development Conventions

### Testing

To run the test suite, use the following command:

```bash
mix test
```

### Database Management

The `aurora_gov` application provides several aliases for managing the database and event store:

*   `mix db.setup`: Creates the event store, runs migrations, and seeds the database.
*   `mix db.reset`: Drops and then sets up the database.
*   `mix event_store.setup`: Creates and initializes the event store.
*   `mix projector.setup`: Creates and migrates the read model projections.
*   `mix projector.reset`: Drops and recreates the projections.

### Asset Management

The `aurora_gov_web` application uses `esbuild` for JavaScript and `tailwind` for CSS. The following commands are available:

*   `mix assets.build`: Builds the assets.
*   `mix assets.deploy`: Builds and minifies assets for production.

## Development Workflow (CQRS + Event Sourcing)

AuroraGov follows a strict CQRS and Event Sourcing pattern using the `Commanded` library. Below is the end-to-end flow for implementing new features or modifying existing ones:

### 1. Command Definition
Define the user's intent in `apps/aurora_gov/lib/aurora_gov/command/`. Commands should be simple structs with validation logic (using `handle_validate/1`).

### 2. Command Handler
Implement the business logic and validation in `apps/aurora_gov/lib/aurora_gov/command_handler/`. The handler receives the aggregate state and the command, and must return one or more events (or an error).

### 3. Command Router
Register the command, handler, and target aggregate in `apps/aurora_gov/lib/aurora_gov/router.ex`.

### 4. Aggregate State
Aggregates in `apps/aurora_gov/lib/aurora_gov/aggregate/` manage the "write model" state. They must implement:
*   `execute/2` (if not using a separate handler).
*   `apply/2`: Updates the aggregate state based on events. This state is used for command validation.

### 5. Events
Define domain events in `apps/aurora_gov/lib/aurora_gov/event/`. Events represent something that has happened and are the source of truth.

### 6. Projectors (Read Model)
Projectors in `apps/aurora_gov/lib/aurora_gov/projector/` transform events into queryable data (PostgreSQL tables).
*   Use `Ecto.Multi` for atomic updates.
*   **PubSub Integration**: Every projector should include a step to return a `projector_update` signal. The main `AuroraGov.Projector` will then broadcast this via `Phoenix.PubSub` to the `"projector_update"` topic.

### 7. Real-Time UI Updates
The web layer (`aurora_gov_web`) reacts to projector updates:
1.  **Subscription**: The main LiveView (`AuroraGov.Web.Live.Panel`) subscribes to the `"projector_update"` topic in its `mount/3`.
2.  **Dispatching**: `handle_info({:projector_update, event}, socket)` receives the message and delegates it to `AuroraGov.Web.Panel.EventRouter.ProjectorUpdate.handle_event/2`.
3.  **Component Notification**: The `EventRouter` uses `send_update/3` to notify specific LiveComponents (e.g., `PowerDetail`, `ProposalDetail`) that data has changed.
4.  **UI Refresh**: Components implement the `update/2` callback to handle the update event and trigger a data refresh (usually by restarting an async task).

### Summary Checklist for New Actions
- [ ] Create Command struct.
- [ ] Create Command Handler.
- [ ] Define Event struct.
- [ ] Register in Command Router.
- [ ] Update Aggregate (`apply/2`).
- [ ] Update/Create Projector and Read Model Schema.
- [ ] Add `projector_update` clause in Projector Multi.
- [ ] Register event in `AuroraGov.Projector` (main).
- [ ] Add handler in `Panel.EventRouter.ProjectorUpdate`.
- [ ] Update LiveComponent to react to the event via `update/2`.
