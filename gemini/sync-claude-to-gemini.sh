#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const os = require("os");
const child_process = require("child_process");

const home = os.homedir();
const geminiAgentsDir = path.join(home, ".gemini/agents");
const geminiSkillsDir = path.join(home, ".gemini/skills");
const installedPluginsPath = path.join(home, ".claude/plugins/installed_plugins.json");
const marketplacesDir = path.join(home, ".claude/plugins/marketplaces");

console.log("Syncing ONLY INSTALLED Claude Agents and Skills to Gemini...");

// 1. Wipe existing directories
if (fs.existsSync(geminiAgentsDir)) {
    fs.rmSync(geminiAgentsDir, { recursive: true, force: true });
}
if (fs.existsSync(geminiSkillsDir)) {
    fs.rmSync(geminiSkillsDir, { recursive: true, force: true });
}

// 2. Create fresh directories
fs.mkdirSync(geminiAgentsDir, { recursive: true });
fs.mkdirSync(geminiSkillsDir, { recursive: true });

function copyDir(src, dest) {
  if (!fs.existsSync(src)) return;
  if (!fs.existsSync(dest)) fs.mkdirSync(dest, { recursive: true });
  
  const entries = fs.readdirSync(src, { withFileTypes: true });
  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    if (entry.isDirectory()) {
      copyDir(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}

// 3. Read installed plugins
let installedPlugins = {};
try {
  if (fs.existsSync(installedPluginsPath)) {
      const data = JSON.parse(fs.readFileSync(installedPluginsPath, "utf8"));
      installedPlugins = data.plugins || {};
  }
} catch (e) {
  console.error("Could not read installed_plugins.json. Proceeding with empty list.");
}

console.log("--> Syncing Skills and Agents from installed plugins...");

const pluginKeys = Object.keys(installedPlugins);
for (const key of pluginKeys) {
  const parts = key.split("@");
  if (parts.length !== 2) continue;
  
  const pluginName = parts[0];
  const marketplaceName = parts[1];
  
  const pluginPath = path.join(marketplacesDir, marketplaceName, "plugins", pluginName);
  
  if (fs.existsSync(pluginPath)) {
    // Copy skills
    const skillsPath = path.join(pluginPath, "skills");
    if (fs.existsSync(skillsPath)) {
      const skillsDirs = fs.readdirSync(skillsPath, { withFileTypes: true });
      for (const dir of skillsDirs) {
        if (dir.isDirectory() && dir.name !== "skills") {
          console.log("  Copying skill: " + dir.name);
          copyDir(path.join(skillsPath, dir.name), path.join(geminiSkillsDir, dir.name));
        }
      }
    }
    
    // Copy agents
    const agentsPath = path.join(pluginPath, "agents");
    if (fs.existsSync(agentsPath)) {
      const agentFiles = fs.readdirSync(agentsPath);
      for (const file of agentFiles) {
        if (file.endsWith(".md")) {
          console.log("  Copying agent: " + file);
          fs.copyFileSync(path.join(agentsPath, file), path.join(geminiAgentsDir, file));
        }
      }
    }
  }
}

// 4. Also sync global ~/.claude/skills and ~/.claude/agents if they exist
const globalSkillsPath = path.join(home, ".claude/skills");
if (fs.existsSync(globalSkillsPath)) {
    const skillsDirs = fs.readdirSync(globalSkillsPath, { withFileTypes: true });
    for (const dir of skillsDirs) {
        if (dir.isDirectory() && dir.name !== "skills") {
            console.log("  Copying global skill: " + dir.name);
            copyDir(path.join(globalSkillsPath, dir.name), path.join(geminiSkillsDir, dir.name));
        }
    }
}

const globalAgentsPath = path.join(home, ".claude/agents");
if (fs.existsSync(globalAgentsPath)) {
    const agentFiles = fs.readdirSync(globalAgentsPath);
    for (const file of agentFiles) {
        if (file.endsWith(".md")) {
            console.log("  Copying global agent: " + file);
            fs.copyFileSync(path.join(globalAgentsPath, file), path.join(geminiAgentsDir, file));
        }
    }
}

console.log("--> Adapting Agent frontmatter for Gemini compatibility...");

const validTools = "[read_file, write_file, grep_search, glob, replace, run_shell_command, web_fetch, list_directory, ask_user, activate_skill]";

if (fs.existsSync(geminiAgentsDir)) {
  fs.readdirSync(geminiAgentsDir).forEach(file => {
    if (!file.endsWith(".md")) return;
    const filePath = path.join(geminiAgentsDir, file);
    let content = fs.readFileSync(filePath, "utf-8");

    if (!content.startsWith("---")) {
        const name = path.basename(file, ".md");
        content = `---\nname: ${name}\ndescription: A specialized agent for ${name}\ntools: ${validTools}\n---\n\n${content}`;
        fs.writeFileSync(filePath, content);
        return;
    }

    const match = content.match(/^---\n([\s\S]*?)\n---/);
    if (!match) return;

    let yaml = match[1];
    const nameMatch = yaml.match(/^name:\s*(.+)$/m);
    
    let descriptionMatch = yaml.match(/^description:\s*([\s\S]*?)(?=\n[a-z]+:|$)/m);
    let descText = descriptionMatch ? descriptionMatch[1].trim() : "";
    
    if (descText === "|" || descText === "") {
        descText = "A specialized agent for this task.";
    } else if (descText.startsWith("|")) {
        descText = descText.replace(/^\|\s*\n/, "").replace(/\n/g, " ").trim();
    }
    
    descText = descText.replace(/"/g, "\\\"");

    const name = nameMatch ? nameMatch[1].trim() : path.basename(file, ".md");

    const newYaml = `name: ${name}\ndescription: "${descText}"\ntools: ${validTools}`;
    
    const newContent = content.replace(/^---\n([\s\S]*?)\n---/, `---\n${newYaml}\n---`);
    fs.writeFileSync(filePath, newContent);
  });
}

console.log("");
console.log("✅ Sync complete!");
console.log("Only INSTALLED Claude workflows are now adapted and available in Gemini CLI.");
