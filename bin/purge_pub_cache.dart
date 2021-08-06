import 'dart:cli' show waitFor;
import 'dart:io';
import 'dart:isolate' show Isolate;

import 'package:args/args.dart';
import 'package:pub_cache/pub_cache.dart';
import 'package:yaml/yaml.dart';

const helpFlag = "help";
const versionFlag = "version";
const directoryOption = "directory";
const yesFlag = "yes";
const quietFlag = "quiet";
const dryRunFlag = "dry-run";

final argParser = ArgParser()
  ..addFlag(helpFlag, abbr: "h", negatable: false, help: "Show this usage.")
  ..addFlag(versionFlag, negatable: false, help: "Show app version and exit.")
  ..addOption(
    directoryOption, abbr: "d",
    help: "Specify a path to handle as pub_cache directory.",
    valueHelp: "path",
  )
  ..addFlag(
    yesFlag, abbr: "y", negatable: false,
    help: "Assume YES to confirm the deletion.",
  )
  ..addFlag(
    quietFlag, abbr: "q", negatable: false,
    help: "No outputs (--yes is assumed to be set).",
  )
  ..addFlag(
    dryRunFlag, abbr: "n", negatable: false,
    help: "Dry-run. Show the packages to delete and exit.",
  );

late final ArgResults argResults;

final String name = "purge_pub_cache";
late final String version;
Future<void> init() async {
  var v; try {
    var pubspecFile; {
      var pubspecFileUri = (
        await Isolate.resolvePackageUri(Uri.parse("package:${name}/"))
      )?.resolve("../pubspec.yaml");
      if (pubspecFileUri == null) return;
      pubspecFile = File.fromUri(pubspecFileUri);
    }

    var pubspec = loadYaml(pubspecFile.readAsStringSync());
    if (pubspec == null) return;
    v = pubspec["version"];
  } finally {
    version = v ?? "unknown";
  }
}

void main(List<String> args) {
  waitFor(init());

  try {
    argResults = argParser.parse(args);
  } catch (_) {
    showUsage();
    return;
  }
  if (argResults[helpFlag] || argResults.rest.isNotEmpty) {
    showUsage();
    return;
  }

  if (argResults[versionFlag]) {
    print("${name} version: ${version}");
    return;
  }

  var pubCache; {
    var path = argResults[directoryOption];
    var dir;
    if (path != null) {
      if (!(dir = Directory(path)).existsSync()) {
        stderr.writeln("No such directory: ${path}.");
        return;
      }
    }
    pubCache = PubCache(dir);
  }
  mayPrint("Using pub-cache directory: ${pubCache.location.path}\n");

  var toDelete = buildToDelete(pubCache);

  var count = toDelete.values.fold<int>(0, (p, e) => p += e.length);
  if (count == 0) {
    mayPrint("No packages to purge.");
    return;
  }
  showListToDelete(toDelete);

  if (argResults[dryRunFlag] || !confirmToDelete(count)) return;

  mayWrite("Deleting ${count} packages... ");
  for (var l in toDelete.values) {
    for (var p in l) {
      p.location.deleteSync(recursive: true);
    }
  }
  mayPrint("done.");
}

void mayPrint(Object object) {
  if (argResults[quietFlag]) return;
  print(object);
}

void mayWrite(Object object) {
  if (argResults[quietFlag]) return;
  stdout.write(object);
}

Map<String, List<Package>> buildToDelete(PubCache pubCache) {
  var toDelete = <String, List<Package>>{};

  for (var p in pubCache.getPackageRefs()) {
    var package = p.resolve();
    if (package == null) continue;

    (toDelete[p.name] ??= []).add(package);
  }
  for (var v in toDelete.values.toList()) {
    if (v.length == 1) {
      toDelete.remove(v[0].name);
      continue;
    }
    v..sort((a, b) => a.version.compareTo(b.version))..removeLast();
  }
  return toDelete;
}

void showListToDelete(Map<String, List<Package>> toDelete) {
  if (argResults[quietFlag]) return;

  print("Packages to be deleted:");
  for (var e in toDelete.entries) {
    print("${e.key}: ${e.value.map((p) => p.version.toString()).join(", ")}");
  }
}

bool confirmToDelete(int count) {
  if (argResults[yesFlag] || argResults[quietFlag]) return true;

  var yesRegExp = RegExp(r"[yY]");
  var noRegExp = RegExp(r"[nN]");

  print("");
  while (true) {
    stdout.write("Are you sure to delete these ${count} packages? [y/N]: ");
    var line = stdin.readLineSync() ?? "";
    if (line.isEmpty || line.startsWith(noRegExp)) {
      print("Aborted.");
      return false;
    }
    if (line.startsWith(yesRegExp)) return true;
  }
}

void showUsage() {
  print("Usage: ${name} [option...]\n");
  print("Options:");
  print(argParser.usage);
}
