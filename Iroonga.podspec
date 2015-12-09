Pod::Spec.new do |s|
  root = "/Users/masaaki.goshima/Development/iroonga"
  s.name         = "Iroonga"
  s.version      = "0.0.1"
  s.summary      = "Groonga for iOS"
  s.description  = ""
  s.homepage     = "http://groonga.org"
  s.author       = { "goccy" => "goccy54@gmail.com" }
  s.source       = { :git => "https://github.com/goccy/iroonga" }
  s.requires_arc = true
  header_search_path = "#{root}/lib/include #{root}/lib/include/groonga #{root}/lib/src"
  s.prefix_header_contents =<<PREFIX_HEADER_CONTENTS
#define HAVE_STDLIB_H
#define HAVE_SYS_TYPES_H
#define HAVE_SYS_PARAM_H
#define HAVE_SYS_MMAN_H
#define HAVE_SYS_TIME_H
#define HAVE_SYS_RESOURCE_H
#define HAVE_SYS_SOCKET_H
#define HAVE_NETINET_IN_H
#define HAVE_NETINET_TCP_H
#define HAVE_SIGNAL_H
#define HAVE_EXECINFO_H
#define HAVE_NETDB_H
#define HAVE_ERRNO_H
#define HAVE_DLFCN_H


#define HAVE_OPEN
#define HAVE_CLOSE
#define HAVE_READ
#define HAVE_WRITE
#define HAVE_UNISTD_H
#define HAVE_PTHREAD_H
#define HAVE_INTTYPES_H
#define GRN_STACK_SIZE 1024


#define CONFIGURE_OPTIONS ""
#define GRN_CONFIG_PATH "/usr/local/etc/groonga/groonga.conf"
#define GRN_DEFAULT_DB_KEY "auto"
#define GRN_DEFAULT_ENCODING "utf8"
#define GRN_LOCK_TIMEOUT 10000000
#define GRN_LOCK_WAIT_TIME_NANOSECOND 1000000
#define GRN_PLUGIN_SUFFIX ".so"
#define GRN_QUERY_EXPANDER_TSV_RELATIVE_SYNONYMS_FILE "synonyms.tsv"
#define GRN_QUERY_EXPANDER_TSV_SYNONYMS_FILE "NONE/etc/groonga/synonyms.tsv"
#define GRN_VERSION "5.0.0"
#define GRN_DEFAULT_MATCH_ESCALATION_THRESHOLD 0
#define GRN_WITH_NFKC 1
#define GRN_WITH_ZLIB 1
#define HAVE_BACKTRACE 1
#define GRN_LOG_PATH ""
#define GRN_PLUGINS_DIR ""
#define PACKAGE "groonga"

#ifdef DEBUG
#undef DEBUG
#endif

PREFIX_HEADER_CONTENTS
  s.xcconfig = {
    HEADER_SEARCH_PATHS:  header_search_path,
  }

  s.ios.frameworks = 'CoreLocation'

  s.subspec 'Iroonga' do |iroonga|
    iroonga.subspec 'Location' do |loc|
      loc.source_files = "Iroonga/Location/*.{h,m}"
    end
  end

  s.subspec 'lib' do |lib|
    lib.subspec 'include' do |inc|
      inc.source_files = "lib/include/*.h"
      inc.subspec 'groonga' do |groonga|
        groonga.source_files = "lib/include/groonga/*.h"
      end
    end
    lib.subspec 'src' do |src|
      src.source_files = "lib/src/*.{c,cpp}", "lib/src/ctx.c", "lib/src/hash.c", "lib/src/str.c", "lib/src/db.c", "lib/src/com.c", "lib/src/command.c", "lib/src/error.c", "lib/src/ii.c", "lib/src/io.c", "lib/src/output.c", "lib/src/*.h"
      src.exclude_files = "lib/src/grn_ecmascript.c", "lib/src/icudump.c"
      
      src.subspec 'dat' do |dat|
        dat.source_files = "lib/src/dat/*.{hpp,cpp}"
      end
    end
  end
end
