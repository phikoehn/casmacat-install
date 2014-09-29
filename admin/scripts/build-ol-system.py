#! /usr/bin/env python

import sys, getopt, json

n, N, ipairs, server = None, None, None, None

def main(argv):
  input_extension = None 
  output_extension = None
  corpus = None
  info = None
  status_fn = "/tmp/build_ol_status" 
  try:
    opts, args = getopt.getopt(argv,"hf:e:",["corpus=","info=","status="])
  except getopt.GetoptError:
    print 'build-ol-system.py -f <input-extension> -e <output-extension> --corpus <corpus> --info <json-info>'
    sys.exit(2)
  for opt, arg in opts:
    if opt in ('-h', ):
      print 'build-ol-system.py -f <input-extension> -e <output-extension> --corpus <corpus> --info <json-info>'
      sys.exit()
    elif opt in ("-f", ):
      input_extension= arg
    elif opt in ("-e", ):
      output_extension = arg
    elif opt in ("--corpus", ):
      corpus = json.loads(arg)
    elif opt in ("--info", ):
      info = json.loads(arg)
    elif opt in ("--status", ):
      status_fn = arg 

  print >> sys.stderr, 'input-extension', input_extension
  print >> sys.stderr, 'output-extension', output_extension
  print >> sys.stderr, 'corpus', corpus 
  print >> sys.stderr, 'info', info 


  from socketIO_client import SocketIO, BaseNamespace

  class OLServer(BaseNamespace):
    def on_error(self, reason, advice):
      print "ERROR", reason, advice 


  #import logging
  #logging.basicConfig(level=logging.DEBUG)


  with SocketIO('localhost', 8765) as socketIO:
    global server 
    server = socketIO.define(OLServer, '/casmacat')

    for c in info["corpus"]:
      ifn = '/opt/casmacat/data/%s-%s/%s.%s' % (input_extension, output_extension, c, input_extension)
      ofn = '/opt/casmacat/data/%s-%s/%s.%s' % (input_extension, output_extension, c, output_extension)

      with open(ifn) as ifd:
        with open(ofn) as ofd:
          global n, N, ipairs
          N = sum(1 for line in open(ifn))
          n = -1

          ipairs = iter(zip(ifd, ofd))

          def process_next(*args):
            global n, N, ipairs, server
            n += 1

            status_fd = open(status_fn, "w")
            print >> status_fd, n, N
            status_fd.close()

            try:  
              source, target = next(ipairs)
              source = source.strip() 
              target = target.strip()
              print >> sys.stderr, "VALIDATE", source, "->", target
              server.emit('validate', {'data': {'source': source, 'target': target}})
            except StopIteration:
              socketIO.disconnect()


          server.on('validateResults', process_next)
          process_next()

          socketIO.wait()

if __name__ == "__main__":
   main(sys.argv[1:])
