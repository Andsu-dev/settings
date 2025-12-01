if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Set Node.js 22 as default
set -gx PATH "$HOME/.nvm/versions/node/v22.20.0/bin" $PATH

# pnpm
set -gx PNPM_HOME "/home/andsu/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

alias code="cursor ."

starship init fish | source
zoxide init fish | source
fzf --fish | source

function cat
    if defaults read -globalDomain AppleInterfaceStyle &> /dev/null
        bat --theme=default $argv
    else
        bat --theme=Github $argv
    end
end

alias ls='eza --icons --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions'
alias cd="z"
set -gx FZF_CTRL_T_OPTS "--style=full --walker-skip=.git,node_modules,target --preview='bat -n --color=always {}' --bind='ctrl-/:change-preview-window(down|hidden|)'"

# set -g fish_greeting "Hello! Ready to code 😎"
set -g fish_greeting

#git
alias gs="git status"
alias ga="git add ."
alias gc="git commit -m"
alias gp="git push"
alias gl="git pull"
alias gco="git checkout"
alias gb="git branch"
alias gcl="git clone"

#docker
alias dc="docker compose"
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dcb="docker compose build"

#nav
alias down="cd ~/Transferências"
alias back="cd .."
alias home="cd"

function dev
    set base ~/projects 

    if test (count $argv) -eq 1 -a "$argv[1]" = "list"
        echo "📁 Projects to $base:"
        ls -1 $base
        return
    end

    if test (count $argv) -eq 2 -a "$argv[1]" = "rm"
        set target "$base/$argv[2]"

        if test -d "$target"
            read confirm

            if test "$confirm" = "y"
                rm -rf "$target"
                echo "🗑 Projeto removido!"
            else
                echo "❎ Cancelado."
            end
        else
            echo "❌ Projeto '$argv[2]' não existe."
        end
        return
    end

    if test (count $argv) -eq 0
        cd $base
        return
    end

    set type ""
    set name ""
    set framework ""
    set package_manager ""

    # Parse arguments
    if test $argv[1] = "--go"
        set type "go"
        set name $argv[2]
    else if test $argv[1] = "--laravel"
        set type "laravel"
        set name $argv[2]
    else if test $argv[1] = "--node"
        set type "node"
        
        # Check for package manager flag
        if test (count $argv) -ge 2
            switch $argv[2]
                case "-pnpm"
                    set package_manager "pnpm"
                    set name $argv[3]
                case "-npm"
                    set package_manager "npm"
                    set name $argv[3]
                case "-yarn"
                    set package_manager "yarn"
                    set name $argv[3]
                case "-bun"
                    set package_manager "bun"
                    set name $argv[3]
                case "*"
                    set name $argv[2]
                    set package_manager "pnpm" # default
            end
        end
        
        if contains -- "--fastify" $argv
            set framework "fastify"
        else if contains -- "--express" $argv
            set framework "express"
        end
    else if test $argv[1] = "--bun"
        set type "bun"
        set package_manager "bun"
        
        if test (count $argv) -ge 2
            switch $argv[2]
                case "-bun"
                    set name $argv[3]
                case "*"
                    set name $argv[2]
            end
        end
        
        if contains -- "--elysia" $argv
            set framework "elysia"
        end
    else
        set name $argv[1]
    end

    if test -z "$name"
        echo "Uso:"
        echo "  dev --node -pnpm nome --fastify"
        echo "  dev --node -npm nome --express"
        echo "  dev --node -bun nome --fastify"
        echo "  dev --bun -bun nome --elysia"
        echo "  dev --bun nome                 → projeto bun vazio"
        echo "  dev --node nome                → projeto node vazio (pnpm default)"
        return
    end

    switch $type
        case node
            mkdir -p $base/$name
            cd $base/$name
            mkdir -p src
            touch .env

            if test -z "$framework"
                echo "📦 Criando projeto Node básico..."
                eval $package_manager init -y
                printf "%s\n" "console.log('Hello Node!')" > src/index.js
            else
                echo "📦 Iniciando projeto Node + Typescript..."
                eval $package_manager init

                eval $package_manager add typescript @types/node tsx -D

                if test "$framework" = "fastify"
                    echo "📦 Instalando Fastify..."
                    eval $package_manager add fastify @fastify/cors @fastify/swagger zod fastify-type-provider-zod @scalar/fastify-api-reference
                    eval $package_manager add -D -E @biomejs/biome
                    eval $package_manager exec biome init
                else
                    echo "📦 Instalando Express..."
                    eval $package_manager add express cors zod
                    eval $package_manager add -D @types/express @types/cors
                end

                printf "%s\n" \
'{
  "$schema": "https://www.schemastore.org/tsconfig",
  "display": "Node 22",
  "_version": "22.0.0",

  "compilerOptions": {
    "lib": ["es2024", "ESNext.Array", "ESNext.Collection", "ESNext.Iterator"],
    "module": "nodenext",
    "target": "es2022",

    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "moduleResolution": "node16"
  }
}' > tsconfig.json

                if test "$framework" = "fastify"
                    printf "%s\n" \
'import Fastify from "fastify";
import { fastifyCors } from "@fastify/cors";
import { fastifySwagger } from "@fastify/swagger";
import {
  jsonSchemaTransform,
  serializerCompiler,
  validatorCompiler,
} from "fastify-type-provider-zod";
import ScalarApiReference from "@scalar/fastify-api-reference";

const app = Fastify();

app.setValidatorCompiler(validatorCompiler);
app.setSerializerCompiler(serializerCompiler);

app.register(fastifyCors, {
  origin: true,
  methods: ["PUT", "PATH", "DELETE", "GET", "POST", "OPTIONS"],
  credentials: true,
});

app.register(fastifySwagger, {
  openapi: {
    info: {
      title: "API",
      description: "new api for development",
      version: "1.0.0",
    },
  },
  transform: jsonSchemaTransform,
});

app.register(ScalarApiReference, {
  routePrefix: "/docs",
});

app.get("/", async () => {
  return { ok: true };
});

app.listen({ port: 3333 }).then(() => {
  console.log("🚀 Server running at http://localhost:3333");
  console.log("📚 Docs running at http://localhost:3333/docs");
});
' > src/server.ts
                else
                    printf "%s\n" \
'import express from "express";
import cors from "cors";

const app = express();
app.use(cors());

app.get("/", (req, res) => {
  res.json({ ok: true });
});

app.listen(3333, () => {
  console.log("🚀 Express server running at http://localhost:3333");
});

' > src/server.ts
                end

                sed -i 's/"scripts": {/"scripts": {\n    "dev": "tsx watch --env-file=.env src\\/server.ts",\n    "build": "tsc",\n    "start": "node dist\\/server.js",\n/' package.json
            end

            printf "%s\n" \
"# Logs
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
lerna-debug.log*
.pnpm-debug.log*

# Diagnostic reports (https://nodejs.org/api/report.html)
report.[0-9]*.[0-9]*.[0-9]*.[0-9]*.json

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Directory for instrumented libs generated by jscoverage/JSCover
lib-cov

# Coverage directory used by tools like istanbul
coverage
*.lcov

# nyc test coverage
.nyc_output

# Grunt intermediate storage (https://gruntjs.com/creating-plugins#storing-task-files)
.grunt

# Bower dependency directory (https://bower.io/)
bower_components

# node-waf configuration
.lock-wscript

# Compiled binary addons (https://nodejs.org/api/addons.html)
build/Release

# Dependency directories
node_modules/
jspm_packages/

# Snowpack dependency directory (https://snowpack.dev/)
web_modules/

# TypeScript cache
*.tsbuildinfo

# Optional npm cache directory
.npm

# Optional eslint cache
.eslintcache

# Optional stylelint cache
.stylelintcache

# Microbundle cache
.rpt2_cache/
.rts2_cache_cjs/
.rts2_cache_es/
.rts2_cache_umd/

# Optional REPL history
.node_repl_history

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# dotenv environment variable files
.env
.env.development.local
.env.test.local
.env.production.local
.env.local

# parcel-bundler cache (https://parceljs.org/)
.cache
.parcel-cache

# Next.js build output
.next
out

# Nuxt.js build / generate output
.nuxt
dist

# Gatsby files
.cache/
# Comment in the public line in if your project uses Gatsby and not Next.js
# https://nextjs.org/blog/next-9-1#public-directory-support
# public

# vuepress build output
.vuepress/dist

# vuepress v2.x temp and cache directory
.temp
.cache

# Docusaurus cache and generated files
.docusaurus

# Serverless directories
.serverless/

# FuseBox cache
.fusebox/

# DynamoDB Local files
.dynamodb/

# TernJS port file
.tern-port

# Stores VSCode versions used for testing VSCode extensions
.vscode-test

# yarn v2
.yarn/cache
.yarn/unplugged
.yarn/build-state.yml
.yarn/install-state.gz
.pnp.*

# Vim swap files
*.swp

# macOS files
.DS_Store

# Clinic
.clinic

# lock files
bun.lockb
package-lock.json
pnpm-lock.yaml
yarn.lock

# editor files
.vscode
.idea

#tap files
.tap/" > .gitignore

            mkdir -p docker
            printf > docker/docker-compose.yml

            git init
            git add .
            git commit -m "chore: initial project"

            echo "✨ Projeto Node criado com sucesso!"

       case bun
    if test "$framework" = "elysia"
        echo "📦 Criando projeto Bun + Elysia..."
        cd $base
        bun create elysia $name
        cd $name
        
        echo "📦 Instalando dependências adicionais..."
        bun add @elysiajs/cors pg drizzle-orm better-auth zod @elysiajs/openapi
        bun add -D drizzle-kit
        
        # Criar tsconfig.json
        printf "%s\n" \
'{
  "$schema": "https://www.schemastore.org/tsconfig",
  "display": "Node 22",
  "_version": "22.0.0",

  "compilerOptions": {
    "lib": ["es2024", "ESNext.Array", "ESNext.Collection", "ESNext.Iterator"],
    "module": "nodenext",
    "target": "es2022",

    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "moduleResolution": "node16"
  }
}' > tsconfig.json
        
        # Criar .env
        touch .env
        
        # Criar pasta docker
        mkdir -p docker
        touch docker/docker-compose.yml
        
        git init
        git add .
        git commit -m "chore: initial project"
        
        echo "✨ Projeto Elysia criado com sucesso!"
        
    else
        echo "📦 Criando projeto Bun básico..."
        mkdir -p $base/$name
        cd $base/$name
        bun init -y
        
        # Criar .env
        touch .env
        
        # Criar estrutura docker
        mkdir -p docker
        touch docker/docker-compose.yml
        
        git init
        git add .
        git commit -m "chore: initial project"
        
        echo "✨ Projeto Bun criado com sucesso!"
    end
end
end
