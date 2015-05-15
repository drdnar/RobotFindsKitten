using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
//using System.Threading.Tasks;

namespace RfkHuffmanCoder
{
    class Program
    {
        static bool Logging = false;

        static void Log(string text = "")
        {
            if (Logging)
                Console.Write(text);
        }

        static void LogLine(string text = "")
        {
            if (Logging)
                Console.WriteLine(text);
        }

        /// <summary>
        /// Class used for forming the Huffman tree.
        /// </summary>
        class Node : IComparable
        {
            /// <summary>
            /// Number of times Symbol appears in text.
            /// </summary>
            public long Frequency = 0;
            /// <summary>
            /// Symbol represented by the Node.
            /// Only valid if the node is a leaf.
            /// </summary>
            public byte Symbol = 0;
            public int Children = 1;
            public int Leaves = 0;
            public Node Left = null;
            public Node Right = null;

            public Node(long freq)
            {
                Frequency = freq;
            }

            public Node(byte code, long freq)
            {
                Symbol = code;
                Frequency = freq;
                Leaves = 1;
            }

            /// <summary>
            /// Returns true if the node is a leaf node.
            /// </summary>
            public bool IsLeaf
            {
                get
                {
                    return Left == null && Right == null;
                }
            }

            /// <summary>
            /// Compares Nodes with respect to their frequency.
            /// Used by the tree building code to sort symbols by frequency.
            /// </summary>
            /// <param name="o"></param>
            /// <returns></returns>
            public int CompareTo(object o)
            {
                Node n = o as Node;
                if (n == null)
                    return 0;
                if (Frequency < n.Frequency)
                    return -1;
                if (Frequency > n.Frequency)
                    return 1;
                return 0;
            }
        }

        /// <summary>
        /// Used for the code that translates bytes into Huffman symbols.
        /// </summary>
        class Huffcode
        {
            /// <summary>
            /// Symbol's code
            /// </summary>
            public int Code;
            /// <summary>
            /// Bit length of code
            /// </summary>
            public int Length;
        }

        static void ShowHelp()
        {
            Console.WriteLine("Usage:");
            Console.WriteLine("RfkHuffmanCoder [-d] [-g \"garbage data to change frequencies\"] [-o outfile] [-n APPVARNAME] infile");
        }

        static void Main(string[] args)
        {
            #region Command line arguments parsing
            Console.WriteLine("robotfindskitten Huffman encoder for RFK for the TI-84 Plus C SE.");
            Console.WriteLine("Version/date: 30 December 2013");
            //Console.WriteLine("")

            bool haveOutfile = false;
            bool haveInfile = false;
            bool haveAppvarName = false;
            string outfile = "";
            string infile = "";
            string appvarname = "";
            string garbage = "";
            Program8x prgm = new Program8x();

            if (args.Length == 0)
            {
                ShowHelp();
                return;
            }
            try
            {
                for (int i = 0; i < args.Length; i++)
                {
                    if (args[i] == "-d")
                        Logging = true;
                    else if (args[i] == "-o" && i != args.Length - 1)
                    {
                        haveOutfile = true;
                        outfile = args[++i];
                    }
                    else if (args[i] == "-n" && i != args.Length - 1)
                    {
                        haveAppvarName = true;
                        appvarname = args[++i];
                    }
                    else if (args[i] == "-g" && i != args.Length - 1)
                    {
                        garbage = args[++i];
                    }
                    else if (i == args.Length - 1)
                    {
                        haveInfile = true;
                        infile = args[i];
                    }
                    else
                    {
                        Console.WriteLine("Syntax error in parameter " + args[i]);
                        ShowHelp();
                        return;
                    }
                }
            }
            catch
            {
                ShowHelp();
                return;
            }
            if (!haveInfile)
            {
                ShowHelp();
                return;
            }
            if (!haveOutfile)
            {
                outfile = System.IO.Path.GetDirectoryName(infile)
                    + System.IO.Path.GetFileNameWithoutExtension(infile) + ".8xv";
                //outfile = "RFKDATA.8xv";
            }
            if (!haveAppvarName)
            {
                appvarname = System.IO.Path.GetFileNameWithoutExtension(outfile).ToUpper();
            }

            Console.WriteLine("Infile: " + infile);
            Console.WriteLine("Outfile: " + outfile);
            Console.WriteLine("Appvar name: " + appvarname);
            #endregion

            #region Read file
            string filename = infile;
            Log("Reading file " + filename + ". . . .");
            string[] file;
            try
            {
                file = System.IO.File.ReadAllLines(filename);
            }
            catch
            {
                Console.WriteLine("Error loading file.");
                return;
            }
            LogLine(" done.");
            #endregion

            // Initalize queue with nodes
            #region Build initial list of input symbols
            Log("Tallying codes. . . .");
            // Whatever.  We're not running this on a big corpus.  Just use whatever is handy, performance be darned.
            List<Node> Nodes = new List<Node>(); // Input symbols with frequency
            Dictionary<byte, Huffcode> Codes = new Dictionary<byte, Huffcode>(); // Association of output codes with their input symbols
            Node n;
            Node m;
            Node o;
            // Build initial tree
            string curline;
            for (int line = 0; line <= file.Length; line++)
            {
                // For each symbol in file . . .
                if (line != file.Length)
                    curline = file[line];
                else
                    curline = garbage;
                for (int i = 0; i < curline.Length; i++)
                {
                    byte b = (byte)curline[i];
                    // Is symbol already known?
                    n = Nodes.Find(x => x.Symbol == b);
                    // If symbol is already known, update symbol count
                    if (n != null)
                        n.Frequency++;
                    else
                    {
                        // If symbol is not known, add it to symbol lists
                        Nodes.Add(new Node(b, 1));
                        Codes.Add(b, new Huffcode());
                    }
                }
                // Newlines are also important.
                // We replace newline with null bytes, so we hardcode 0.
                n = Nodes.Find(x => x.Symbol == 0);
                if (n != null)
                    n.Frequency++;
                else
                {
                    Nodes.Add(new Node(0, 1));
                    Codes.Add(0, new Huffcode());
                }
            }
            LogLine(" done.");
            LogLine();
            #endregion

            // Stats just for fun
            Nodes.Sort();
            LogLine("Codes in language: " + Nodes.Count);
            foreach (Node node in Nodes)
            {
                LogLine("Code " + (node.Symbol != 0 ? (char)node.Symbol : ' ') + " (" + node.Symbol.ToString("X2") + "): " + node.Frequency.ToString());
            }
            LogLine();

            #region Generate Huffman tree
            LogLine("Generating Huffman tree. . . .");
            // This dequeues nodes and creates new nodes with their combined frequency.
            // See the Wikipedia article on Huffman compression for more information.
            while (Nodes.Count > 1) // As long as there is two or more nodes remaining, there is work to do.
            {
                // Left node
                n = Nodes.First();
                Nodes.Remove(n);
                if (n.IsLeaf)
                    Log("Dequeue " + n.Symbol.ToString("X2") + " @ " + n.Frequency + ", ");
                else
                    Log("Dequeue <internal> @ " + n.Frequency + ", ");
                // Right node
                m = Nodes.First();
                Nodes.Remove(m);
                if (m.IsLeaf)
                    Log("Dequeue " + m.Symbol.ToString("X2") + " @ " + m.Frequency + ", ");
                else
                    Log("Dequeue <internal> @ " + m.Frequency + ", ");
                // Make new parent node, and adjust the tree accordingly.
                o = new Node(n.Frequency + m.Frequency);
                o.Left = n;
                o.Right = m;
                o.Children += n.Children + m.Children;
                o.Leaves = n.Leaves + m.Leaves;
                Nodes.Add(o);
                LogLine("Enqueue <internal> @ " + o.Frequency);
                // Items need to be removed from the queue in order, and I'm too lazy to do this properly.
                // .NET may well have the methods I need to do this without resorting all the time, but LAZY.
                Nodes.Sort();
            }
            // We don't dequeue this first node, so Nodes.First() will be our reference to the top of the tree.
            o = Nodes.First();
            LogLine("Tree complete.  Leaves: " + o.Leaves + ", Total nodes: " + o.Children);
            LogLine();
            n = o.Left;
            LogLine("Left leaves: " + n.Leaves + ", left nodes: " + n.Children + ", size: " + (n.Leaves + (n.Children - n.Leaves) * 2));
            m = o.Right;
            LogLine("Right leaves: " + m.Leaves + ", right nodes: " + m.Children + ", size: " + (m.Leaves + (m.Children - m.Leaves) * 2));
            #endregion

            #region Initalize appvar
            byte[] data = new byte[65500]; // About the largest possible size of appvar
            byte[] header = new byte[] {
                (byte)'R', (byte)'F', (byte)'K', (byte)' ', (byte)'d', (byte)'a', (byte)'t', (byte)'a'
            };
            int location = 0;
            for (int i = 0; i < header.Length; i++)
            {
                data[i] = header[location++];
            }
            // Version field, not really used
            location += 2;
            // Number of items
            data[location++] = (byte)(file.Length & 0xFF);
            data[location++] = (byte)(file.Length >> 8);
            int tablelocation = location;
            location += file.Length * 2;
            #endregion

            #region Serialize the tree into the appvar
            // Now serialize the tree
            int treeStartLoc = location;
            LogLine("Serializing tree. . . .");
            // Recursive operation
            try
            {
                Serialize(Nodes.First(), data, ref location, Codes, 0, 0);
            }
            catch
            {
                // Abort; there's nothing we can do.
                return;
            }
            LogLine("Tree serialization complete.");
            Log("Tree size: ");
            Log((location - treeStartLoc).ToString());
            LogLine(" bytes.");
            LogLine();
            #endregion

            #region Compress text
            LogLine("Now compressing text. . . .");
            int dataStartLoc = location;
            Huffcode p;
            int bit = 0;
            // For each input symbol in source. . .
            for (int line = 0; line < file.Length; line++)
            {
                int startloc = location;
                curline = file[line];
                LogLine(curline);
                // Write entry into table
                data[tablelocation++] = (byte)(location & 0xFF);
                data[tablelocation++] = (byte)(location >> 8);
                Log(location.ToString("X4") + " ");
                // Compress text
                for (int i = 0; i < curline.Length; i++)
                {
                    p = Codes[(byte)curline[i]];
                    WriteBits(data, ref bit, ref location, p.Code, p.Length);
                }
                // Add null terminator, so decoder knows it's time to stop decoding
                p = Codes[0];
                WriteBits(data, ref bit, ref location, p.Code, p.Length);
                // Now reset bit counter, because all strings must start byte-aligned
                if (bit != 0)
                {
                    bit = 0;
                    location++;
                }
                // For verification
                for (int i = startloc; i < location; i++)
                    Log(ToBinaryLittleEndian(data[i], 8) + " ");
                LogLine();
                for (int i = startloc; i < location; i++)
                    Log(data[i].ToString("X2") + " ");
                LogLine();
            }
            LogLine("Compression complete.");
            Log("Data size: ");
            Log((location - dataStartLoc).ToString());
            LogLine(" bytes.");
            LogLine();
            #endregion

            #region Write appvar
            Log("Writing 8xv. . . .");
            prgm.Name = appvarname.Length <= 8 ? appvarname : appvarname.Substring(0, 8);
            prgm.Type = VariableType.AppVarObj;
            // Copy data from initial byte array into output array
            byte[] data2 = new byte[location];
            for (int i = 0; i < location; i++)
            {
                data2[i] = data[i];
            }
            prgm.Data = data2;
            System.IO.File.WriteAllBytes(outfile, prgm.Export());
            LogLine(" done.");
            #endregion

            Console.WriteLine("Compression complete.");
            //Console.ReadKey();
        }

        /// <summary>
        /// Used for logging the tree structure.
        /// </summary>
        /// <param name="depth"></param>
        static void Indent(int depth)
        {
            for (int i = 0; i < depth; i++)
                Log(" ");
        }

        /// <summary>
        /// Converts input binary data into a string, with the LSB first.
        /// This is needed because I decided to start Huffman codes from bit 0.
        /// After all, the Z80 is little-endian.
        /// </summary>
        /// <param name="val"></param>
        /// <param name="length"></param>
        /// <returns></returns>
        static string ToBinaryLittleEndian(int val, int length)
        {
            string s = "";
            for (int i = 0; i < length; i++)
            {
                if ((val & 1) == 1)
                    s = s + "1";
                else
                    s = s + "0";
                val = val >> 1;
            }
            return s;
        }

        /// <summary>
        /// This is the method that contains the logic for,
        /// first, computing the output codes for symbols in the tree;
        /// and second, serializing the Huffman tree.
        /// </summary>
        /// <param name="tree">Reference to tree to serialize.</param>
        /// <param name="data">Output array into which to serialize tree.</param>
        /// <param name="location">Offset from array into which to write data data.</param>
        /// <param name="Codes">List of associations between input symbols and output codes.</param>
        /// <param name="code">Current code being built.</param>
        /// <param name="depth">Number of levels deep this method has recursed. This is used for knowing the output code length.</param>
        static void Serialize(Node tree, byte[] data, ref int location, Dictionary<byte, Huffcode> Codes, int code, int depth)
        {
            // If our node is a leaf, don't recurse and serialize output symbol information.
            if (tree.IsLeaf)
            {
                Log(location.ToString("X4") + ": ");
                if (tree.Symbol > 0x7E || (tree.Symbol < 0x20 && tree.Symbol != 0))
                {
                    LogLine("Invalid input symbol " + tree.Symbol.ToString("X2"));
                    Console.WriteLine("Invalid input character into input data: " + (char)tree.Symbol);
                    throw new ArgumentOutOfRangeException("Invalid input symbol.");
                }
                data[location++] = (byte)(0x80 | tree.Symbol);
                Codes[tree.Symbol].Code = code;
                Codes[tree.Symbol].Length = depth;
                Indent(depth);
                LogLine(data[location - 1].ToString("X2") + " " + (tree.Symbol == 0 ? ' ' : (char)tree.Symbol) + " " + tree.Symbol.ToString("X2") 
                    + ", c: " + code.ToString("X2") + " " + depth + " " + ToBinaryLittleEndian(code, depth));
                return;
            }
            // else
            // All nodes either have two children or no children.
            // Write the data for the left and right children to the tree.
            Log(location.ToString("X4") + ": ");
            data[location++] = 1 + 1; // Offset to next node
            Indent(depth);
            LogLine(data[location - 1].ToString("X2") + " " + (data[location - 1] + location - 1).ToString("X4") + " l: " + tree.Left.Leaves + ", ch: " + tree.Left.Children);
            if (data[location - 1] > 127)
            {
                LogLine("ERROR: LEFT TREE TOO LARGE");
                Console.WriteLine("Error building Huffman tree: too many symbols for 7-bit format.");
                throw new ArgumentOutOfRangeException("Huffman left tree has too many children.");
            }
            Log(location.ToString("X4") + ": ");
            data[location++] = (byte)(1 + tree.Left.Leaves + (tree.Left.Children - tree.Left.Leaves) * 2);
            Indent(depth);
            LogLine(data[location - 1].ToString("X2") + " " + (data[location - 1] + location - 1).ToString("X4") + " r: " + tree.Right.Leaves + ", ch: " + tree.Right.Children);
            if (data[location - 1] > 127)
            {
                LogLine("ERROR: RIGHT TREE TOO LARGE");
                Console.WriteLine("Error building Huffman tree: too many symbols for 7-bit format.");
                throw new ArgumentOutOfRangeException("Huffman right tree has too many children.");
            }
            Serialize(tree.Left, data, ref location, Codes, code, depth + 1);
            Serialize(tree.Right, data, ref location, Codes, code | 1 << depth, depth + 1);
            
        }

        /// <summary>
        /// Used for writing compressed data output codes to file.
        /// </summary>
        /// <param name="Data">Output data array</param>
        /// <param name="Bit">Bit offset from which to being writing, as well as next offset for next bit.</param>
        /// <param name="Location">Byte offset from start of array to write to. Incremented if necessary.</param>
        /// <param name="bits">Data to write.</param>
        /// <param name="length">Number of bits to write.</param>
        static void WriteBits(byte[] Data, ref int Bit, ref int Location, int bits, int length)
        {
            for (int i = 0; i < length; i++)
            {
                WriteBit(Data, ref Bit, ref Location, bits & 1);
                bits = bits >> 1;
            }
        }

        /// <summary>
        /// Writes a single bit. This could have been optimized a lot
        /// by combining it with WriteBits and doing all bits in a byte at once.
        /// But I don't feel like thinking hard about that logic.
        /// </summary>
        /// <param name="Data"></param>
        /// <param name="Bit"></param>
        /// <param name="Location"></param>
        /// <param name="bit"></param>
        static void WriteBit(byte[] Data, ref int Bit, ref int Location, int bit)
        {
            Data[Location] |= (byte)(bit << Bit++);
            if (Bit > 7)
            {
                Bit = 0;
                Location++;
            }
        }

        
    }
}
