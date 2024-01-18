<Query Kind="Program" />

void Main()
{
	// Write code to test your extensions here. Press F5 to compile and run.
}

static object ToDump(object input) =>
	input switch
	{
		NiceIO.NPath npath => npath.ToString(),
		_ => input
	};

namespace NiceIO
{
    [DebuggerDisplay("{FileName} ({ToString()})")]
    public class NPath : IEquatable<NPath>, IComparable
    {
        static readonly StringComparison PathStringComparison = IsLinux() ? StringComparison.Ordinal : StringComparison.OrdinalIgnoreCase;

        readonly string[] _elements;
        readonly bool _isRelative;
        readonly string? _driveLetter;

        #region construction

        public NPath(string path)
        {
            if (path == null)
                throw new ArgumentNullException();

            path = ParseDriveLetter(path, out _driveLetter);

            if (path == "/")
            {
                _isRelative = false;
                _elements = new string[] {};
            }
            else
            {
                var split = path.Split('/', '\\');

                _isRelative = _driveLetter == null && IsRelativeFromSplitString(split);
                _elements = ParseSplitStringIntoElements(split.Where(s => s.Length > 0)).ToArray();
            }
        }

        NPath(IEnumerable<string> elements, bool isRelative, string driveLetter)
        {
            _elements = elements.ToArray();
            _isRelative = isRelative;
            _driveLetter = driveLetter;
        }

        List<string> ParseSplitStringIntoElements(IEnumerable<string> inputs)
        {
            var stack = new List<string>();

            foreach (var input in inputs.Where(input => input.Length != 0))
            {
                if (input == ".")
                {
                    if ((stack.Count > 0) && (stack.Last() != "."))
                        continue;
                }
                else if (input == "..")
                {
                    if (HasNonDotDotLastElement(stack))
                    {
                        stack.RemoveAt(stack.Count - 1);
                        continue;
                    }
                    if (!_isRelative)
                        throw new ArgumentException("You cannot create a path that tries to .. past the root");
                }
                stack.Add(input);
            }
            return stack;
        }

        static bool HasNonDotDotLastElement(List<string> stack)
        {
            return stack.Count > 0 && stack[stack.Count - 1] != "..";
        }

        string ParseDriveLetter(string path, out string driveLetter)
        {
            if (path.Length >= 2 && path[1] == ':')
            {
                driveLetter = path[0].ToString();
                return path.Substring(2);
            }

            driveLetter = null;
            return path;
        }

        static bool IsRelativeFromSplitString(string[] split)
        {
            if (split.Length < 2)
                return true;

            return split[0].Length != 0 || !split.Any(s => s.Length > 0);
        }

        public NPath Combine(params string[] append)
        {
            return Combine(append.AsEnumerable());
        }

        public NPath Combine(IEnumerable<string> append)
        {
            return Combine(append.Select(a => new NPath(a)));
        }

        public NPath Combine(params NPath[] append)
        {
            return Combine(append.AsEnumerable());
        }

        public NPath Combine(IEnumerable<NPath> append)
        {
            return new NPath(
                ParseSplitStringIntoElements(_elements.Concat(append.SelectMany(
                    p => p.IsRelative
                        ? p._elements
                        : throw new ArgumentException("You cannot .Combine a non-relative path")))),
                _isRelative,
                _driveLetter);
        }

        public NPath Parent
        {
            get
            {
                if (_elements.Length == 0)
                    throw new InvalidOperationException ("Parent is called on an empty path");

                var newElements = _elements.Take (_elements.Length - 1).ToArray ();

                return new NPath (newElements, _isRelative, _driveLetter);
            }
        }

        public NPath RelativeTo(NPath path)
        {
            if (!IsChildOf(path))
            {
                if (!IsRelative && !path.IsRelative && _driveLetter != path._driveLetter)
                    throw new ArgumentException("Path.RelativeTo() was invoked with two paths that are on different volumes. invoked on: " + ToString() + " asked to be made relative to: " + path);

                NPath commonParent = null;
                foreach (var parent in RecursiveParents)
                {
                    commonParent = path.RecursiveParents.FirstOrDefault(otherParent => otherParent == parent);

                    if (commonParent != null)
                        break;
                }

                if (commonParent == null)
                    throw new ArgumentException("Path.RelativeTo() was unable to find a common parent between " + ToString() + " and " + path);

                if (IsRelative && path.IsRelative && commonParent.IsEmpty())
                    throw new ArgumentException("Path.RelativeTo() was invoked with two relative paths that do not share a common parent.  Invoked on: " + ToString() + " asked to be made relative to: " + path);

                var depthDiff = path.Depth - commonParent.Depth;
                return new NPath(Enumerable.Repeat("..", depthDiff).Concat(_elements.Skip(commonParent.Depth)).ToArray(), true, null);
            }

            return new NPath(_elements.Skip(path._elements.Length).ToArray(), true, null);
        }

        public NPath ChangeExtension(string extension)
        {
            ThrowIfRoot();

            var newElements = (string[])_elements.Clone();
            newElements[newElements.Length - 1] = Path.ChangeExtension(_elements[_elements.Length - 1], WithDot(extension));
            if (extension == string.Empty)
                newElements[newElements.Length - 1] = newElements[newElements.Length - 1].TrimEnd('.');
            return new NPath(newElements, _isRelative, _driveLetter);
        }
        #endregion construction

        #region inspection

        public bool IsRelative
        {
            get { return _isRelative; }
        }

        public string FileName
        {
            get
            {
                ThrowIfRoot();

                return _elements.Last();
            }
        }

        public string FileNameWithoutExtension
        {
            get { return Path.GetFileNameWithoutExtension (FileName); }
        }

        public IReadOnlyList<string> Elements
        {
            get { return _elements; }
        }

        public string DriveLetter
        {
            get { return _driveLetter; }
		}

		public int Depth
		{
			get { return _elements.Length; }
		}

        public bool Exists(string append = "")
        {
            return Exists(new NPath(append));
        }

        public bool Exists(NPath append)
        {
            return FileExists(append) || DirectoryExists(append);
        }

        public bool DirectoryExists(string append = "")
        {
            return DirectoryExists(new NPath(append));
        }

        public bool DirectoryExists(NPath append)
        {
            return Directory.Exists(Combine(append).ToString());
        }

        public bool FileExists(string append = "")
        {
            return FileExists(new NPath(append));
        }

        public bool FileExists(NPath append)
        {
            return File.Exists(Combine(append).ToString());
        }

        public string ExtensionWithDot
        {
            get
            {
                if (IsRoot)
                    throw new ArgumentException("A root directory does not have an extension");

                var last = _elements.Last();
                var index = last.LastIndexOf('.');
                if (index < 0) return String.Empty;
                return last.Substring(index);
            }
        }

        public string ExtensionWithoutDot
        {
            get
            {
                if (IsRoot)
                    throw new ArgumentException("A root directory does not have an extension");

                var last = _elements.Last();
                var index = last.LastIndexOf('.');
                if (index < 0) return String.Empty;
                return last.Substring(index + 1);
            }
        }
        public string InQuotes()
        {
            return "\"" + ToString() + "\"";
        }

        public string InQuotes(SlashMode slashMode)
        {
            return "\"" + ToString(slashMode) + "\"";
        }

        [DebuggerStepThrough]
        public override string ToString()
        {
            return ToString(SlashMode.Native);
        }

        public string ToString(SlashMode slashMode)
        {
            // Check if it's linux root /
            if (IsRoot && string.IsNullOrEmpty(_driveLetter))
                return Slash(slashMode).ToString();

            if (_isRelative && _elements.Length == 0)
                return ".";

            var sb = new StringBuilder();
            if (_driveLetter != null)
            {
                sb.Append(_driveLetter);
                sb.Append(":");
            }
            if (!_isRelative)
                sb.Append(Slash(slashMode));
            var first = true;
            foreach (var element in _elements)
            {
                if (!first)
                    sb.Append(Slash(slashMode));

                sb.Append(element);
                first = false;
            }
            return sb.ToString();
        }

        [DebuggerStepThrough]
        public static implicit operator string(NPath path)
        {
            return path.ToString();
        }

        static char Slash(SlashMode slashMode)
        {
            switch (slashMode)
            {
                case SlashMode.Backward:
                    return '\\';
                case SlashMode.Forward:
                    return '/';
                default:
                    return Path.DirectorySeparatorChar;
            }
        }

        public override bool Equals(Object obj)
        {
            if (obj == null)
                return false;

            // If parameter cannot be cast to Point return false.
            var p = obj as NPath;
            if ((Object)p == null)
                return false;

            return Equals(p);
        }

        public bool Equals(NPath p)
        {
            if (p._isRelative != _isRelative)
                return false;

            if (!string.Equals(p._driveLetter, _driveLetter, PathStringComparison))
                return false;

            if (p._elements.Length != _elements.Length)
                return false;

            for (var i = 0; i != _elements.Length; i++)
                if (!string.Equals(p._elements[i], _elements[i], PathStringComparison))
                    return false;

            return true;
        }

        public static bool operator ==(NPath a, NPath b)
        {
            // If both are null, or both are same instance, return true.
            if (ReferenceEquals(a, b))
                return true;

            // If one is null, but not both, return false.
            if (((object)a == null) || ((object)b == null))
                return false;

            // Return true if the fields match:
            return a.Equals(b);
        }

        public override int GetHashCode()
        {
            unchecked
            {
                int hash = 17;
                // Suitable nullity checks etc, of course :)
                hash = hash * 23 + _isRelative.GetHashCode();
                foreach (var element in _elements)
                    hash = hash * 23 + element.GetHashCode();
                if (_driveLetter != null)
                    hash = hash * 23 + _driveLetter.GetHashCode();
                return hash;
            }
        }

        public int CompareTo(object obj)
        {
            if (obj == null)
                return -1;

            return ToString().CompareTo(((NPath)obj).ToString());
        }

        public static bool operator !=(NPath a, NPath b)
        {
            return !(a == b);
        }

        public bool HasExtension(params string[] extensions)
        {
            var extensionWithDotLower = ExtensionWithDot.ToLower();
            return extensions.Any(e => WithDot(e).ToLower() == extensionWithDotLower);
        }

        static string WithDot(string extension)
        {
            return extension.StartsWith(".") ? extension : "." + extension;
        }

        bool IsEmpty()
        {
            return _elements.Length == 0;
        }

        public bool IsRoot
        {
            get { return _elements.Length == 0 && !_isRelative; }
        }

        #endregion inspection

        #region directory enumeration

        public IEnumerable<NPath> Files(string filter, bool recurse = false)
        {
			return Directory.GetFiles(ToString(), filter, recurse ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly).Select(s => new NPath(s));
        }

        public IEnumerable<NPath> Files(bool recurse = false)
        {
            return Files("*", recurse);
        }

        public IEnumerable<NPath> Contents(string filter, bool recurse = false)
        {
            return Files(filter, recurse).Concat(Directories(filter, recurse));
        }

        public IEnumerable<NPath> Contents(bool recurse = false)
        {
            return Contents("*", recurse);
        }

        public IEnumerable<NPath> Directories(string filter, bool recurse = false)
        {
			return Directory.GetDirectories(ToString(), filter, recurse ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly).Select(s => new NPath(s));
        }

        public IEnumerable<NPath> Directories(bool recurse = false)
        {
            return Directories("*", recurse);
        }

        public NPath TildeExpand()
        {
            // implementing only the most basic part of https://www.gnu.org/software/bash/manual/html_node/Tilde-Expansion.html

            if (!IsRelative || _elements.FirstOrDefault() != "~")
                return this;

            return HomeDirectory.Combine(_elements.Skip(1));
        }

        #endregion

        #region filesystem writing operations
        public NPath CreateFile()
        {
            ThrowIfRelative();
            ThrowIfRoot();
            EnsureParentDirectoryExists();
	        File.WriteAllBytes(ToString(), Array.Empty<byte>());
            return this;
        }

        public NPath CreateFile(string file)
        {
            return CreateFile(new NPath(file));
        }

        public NPath CreateFile(NPath file)
        {
            if (!file.IsRelative)
                throw new ArgumentException("You cannot call CreateFile() on an existing path with a non relative argument");
            return Combine(file).CreateFile();
        }

        public NPath CreateDirectory()
        {
            ThrowIfRelative();

            if (IsRoot)
                throw new NotSupportedException("CreateDirectory is not supported on a root level directory because it would be dangerous:" + ToString());

            Directory.CreateDirectory(ToString());
            return this;
        }

        public NPath CreateDirectory(string directory)
        {
            return CreateDirectory(new NPath(directory));
        }

        public NPath CreateDirectory(NPath directory)
        {
            if (!directory.IsRelative)
                throw new ArgumentException("Cannot call CreateDirectory with an absolute argument");

            return Combine(directory).CreateDirectory();
        }

        public NPath Copy(string dest)
        {
            return Copy(new NPath(dest));
        }

        public NPath Copy(string dest, Func<NPath, bool> fileFilter)
        {
            return Copy(new NPath(dest), fileFilter);
        }

        public NPath Copy(NPath dest)
        {
            return Copy(dest, p => true);
        }

        public NPath Copy(NPath dest, Func<NPath, bool> fileFilter)
        {
            ThrowIfRelative();
            if (dest.IsRelative)
                dest = Parent.Combine(dest);

            if (dest.DirectoryExists())
                return CopyWithDeterminedDestination(dest.Combine(FileName), fileFilter);

            return CopyWithDeterminedDestination (dest, fileFilter);
        }

        public NPath MakeAbsolute()
        {
            if (!IsRelative)
                return this;

            return NPath.CurrentDirectory.Combine (this);
        }

        NPath CopyWithDeterminedDestination(NPath absoluteDestination, Func<NPath,bool> fileFilter)
        {
            if (absoluteDestination.IsRelative)
                throw new ArgumentException ("absoluteDestination must be absolute");

            if (FileExists())
            {
                if (!fileFilter(absoluteDestination))
                    return null;

                absoluteDestination.EnsureParentDirectoryExists();

                File.Copy(ToString(), absoluteDestination.ToString(), true);
                return absoluteDestination;
            }

            if (DirectoryExists())
            {
                absoluteDestination.EnsureDirectoryExists();
                foreach (var thing in Contents())
                    thing.CopyWithDeterminedDestination(absoluteDestination.Combine(thing.RelativeTo(this)), fileFilter);
                return absoluteDestination;
            }

            throw new ArgumentException("Copy() called on path that doesnt exist: " + ToString());
        }

        public void Delete(DeleteMode deleteMode = DeleteMode.Normal)
        {
            ThrowIfRelative();

            if (IsRoot)
                throw new NotSupportedException("Delete is not supported on a root level directory because it would be dangerous:" + ToString());

            if (FileExists())
                File.Delete(ToString());
            else if (DirectoryExists())
                try
                {
                    Directory.Delete(ToString(), true);
                }
                catch (IOException)
                {
                    if (deleteMode == DeleteMode.Normal)
                        throw;
                }
            else
                throw new InvalidOperationException("Trying to delete a path that does not exist: " + ToString());
        }

        public void DeleteIfExists(DeleteMode deleteMode = DeleteMode.Normal)
        {
            ThrowIfRelative();

            if (FileExists() || DirectoryExists())
                Delete(deleteMode);
        }

        public NPath DeleteContents()
        {
            ThrowIfRelative();

            if (IsRoot)
                throw new NotSupportedException("DeleteContents is not supported on a root level directory because it would be dangerous:" + ToString());

            if (FileExists())
                throw new InvalidOperationException("It is not valid to perform this operation on a file");

            if (DirectoryExists())
            {
                try
                {
                    Files().Delete();
                    Directories().Delete();
                }
                catch (IOException)
                {
                    if (Files(true).Any())
                        throw;
                }

                return this;
            }

            return EnsureDirectoryExists();
        }

        public static NPath CreateTempDirectory(string myprefix)
        {
            var random = new Random();
            while (true)
            {
                var candidate = new NPath(Path.GetTempPath() + "/" + myprefix + "_" + random.Next());
                if (!candidate.Exists())
                    return candidate.CreateDirectory();
            }
        }

        public NPath Move(string dest)
        {
            return Move(new NPath(dest));
        }

        public NPath Move(NPath dest)
        {
            ThrowIfRelative();

            if (IsRoot)
                throw new NotSupportedException("Move is not supported on a root level directory because it would be dangerous:" + ToString());

            if (dest.IsRelative)
                return Move(Parent.Combine(dest));

            if (dest.DirectoryExists())
                return Move(dest.Combine(FileName));

            if (FileExists())
            {
                dest.EnsureParentDirectoryExists();
                File.Move(ToString(), dest.ToString());
                return dest;
            }

            if (DirectoryExists())
            {
                Directory.Move(ToString(), dest.ToString());
                return dest;
            }

            throw new ArgumentException("Move() called on a path that doesn't exist: " + ToString());
        }

        #endregion

        #region special paths

        public static NPath CurrentDirectory
        {
			get
			{
				return new NPath(Directory.GetCurrentDirectory());
			}
		}

		public static NPath HomeDirectory => new(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile));
		public static NPath ProgramFilesDirectory => new(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles));
		public static NPath SystemTempDirectory => new(Path.GetTempPath());

		#endregion

		public void ThrowIfRelative()
		{
			if (_isRelative)
				throw new ArgumentException("You are attempting an operation on a Path that requires an absolute path, but the path is relative");
		}

		public void ThrowIfRoot()
		{
			if (IsRoot)
				throw new ArgumentException("You are attempting an operation that is not valid on a root level directory");
		}

		public NPath EnsureDirectoryExists(string append = "")
		{
			return EnsureDirectoryExists(new NPath(append));
		}

		public NPath EnsureDirectoryExists(NPath append)
		{
			var combined = Combine(append);
			if (combined.DirectoryExists())
				return combined;
			combined.EnsureParentDirectoryExists();
			combined.CreateDirectory();
			return combined;
		}

		public NPath EnsureParentDirectoryExists()
		{
			var parent = Parent;
			parent.EnsureDirectoryExists();
			return parent;
		}

		public NPath FileMustExist()
		{
			if (!FileExists())
			{
				if (DirectoryExists())
					throw new FileNotFoundException($"Found directory instead of file '{ToString()}'", ToString());

				throw new FileNotFoundException($"Could not find file '{ToString()}'", ToString());
			}

			return this;
		}

		public NPath DirectoryMustExist()
		{
			if (!DirectoryExists())
			{
				if (FileExists())
					throw new DirectoryNotFoundException($"Found file instead of directory '{ToString()}'");

				throw new DirectoryNotFoundException($"Could not find directory '{ToString()}'");
			}

			return this;
		}

		public bool IsChildOf(string potentialBasePath)
		{
			return IsChildOf(new NPath(potentialBasePath));
		}

		public bool IsChildOf(NPath potentialBasePath)
		{
			if ((IsRelative && !potentialBasePath.IsRelative) || !IsRelative && potentialBasePath.IsRelative)
				throw new ArgumentException("You can only call IsChildOf with two relative paths, or with two absolute paths");

			// If the other path is the root directory, then anything is a child of it as long as it's not a Windows path
			if (potentialBasePath.IsRoot)
			{
				if (_driveLetter != potentialBasePath._driveLetter)
					return false;
				return true;
			}

			if (IsEmpty())
				return false;

			if (Equals(potentialBasePath))
				return true;

			return Parent.IsChildOf(potentialBasePath);
		}

		public IEnumerable<NPath> RecursiveParents
		{
			get
			{
				var candidate = this;
				while (true)
				{
					if (candidate.IsEmpty())
						yield break;

					candidate = candidate.Parent;
					yield return candidate;
				}
			}
		}

		public NPath ParentContaining(string needle, bool returnAppended = false)
		{
			return ParentContaining(new NPath(needle), returnAppended);
		}

		public NPath ParentContaining(NPath needle, bool returnAppended = false)
		{
			ThrowIfRelative();

			var found = RecursiveParents.FirstOrDefault(p => p.Exists(needle));
			if (returnAppended && found != null)
				found = found.Combine(needle);

			return found;
		}

		public NPath WriteAllText(string contents)
		{
			ThrowIfRelative();
			EnsureParentDirectoryExists();
			File.WriteAllText(ToString(), contents);
			return this;
		}

		public string ReadAllText()
		{
			ThrowIfRelative();
			return File.ReadAllText(ToString());
		}

		public NPath WriteAllLines(params string[] contents)
		{
			ThrowIfRelative();
			EnsureParentDirectoryExists();
			File.WriteAllLines(ToString(), contents);
			return this;
		}

		public string[] ReadAllLines()
		{
			ThrowIfRelative();
			return File.ReadAllLines(ToString());
		}

		public IEnumerable<NPath> CopyFiles(NPath destination, bool recurse, Func<NPath, bool>? fileFilter = null)
		{
			destination.EnsureDirectoryExists();
			return Files(recurse).Where(fileFilter ?? AlwaysTrue).Select(file => file.Copy(destination.Combine(file.RelativeTo(this)))).ToArray();
		}

		public IEnumerable<NPath> MoveFiles(NPath destination, bool recurse, Func<NPath, bool>? fileFilter = null)
		{
			if (IsRoot)
				throw new NotSupportedException("MoveFiles is not supported on this directory because it would be dangerous:" + ToString());

			destination.EnsureDirectoryExists();
			return Files(recurse).Where(fileFilter ?? AlwaysTrue).Select(file => file.Move(destination.Combine(file.RelativeTo(this)))).ToArray();
		}

		static bool AlwaysTrue(NPath p)
		{
			return true;
		}

		static bool IsLinux()
		{
			return Directory.Exists("/proc");
		}
		public static implicit operator NPath(string input)
		{
			return new NPath(input);
		}
	}

	public static class NPathExtensions
	{
		public static IEnumerable<NPath> Copy(this IEnumerable<NPath> self, string dest)
		{
			return Copy(self, new NPath(dest));
		}

		public static IEnumerable<NPath> Copy(this IEnumerable<NPath> self, NPath dest)
		{
			if (dest.IsRelative)
				throw new ArgumentException("When copying multiple files, the destination cannot be a relative path");
			dest.EnsureDirectoryExists();
			return self.Select(p => p.Copy(dest.Combine(p.FileName))).ToArray();
		}

		public static IEnumerable<NPath> Move(this IEnumerable<NPath> self, string dest)
		{
			return Move(self, new NPath(dest));
		}

		public static IEnumerable<NPath> Move(this IEnumerable<NPath> self, NPath dest)
		{
			if (dest.IsRelative)
				throw new ArgumentException("When moving multiple files, the destination cannot be a relative path");
			dest.EnsureDirectoryExists();
			return self.Select(p => p.Move(dest.Combine(p.FileName))).ToArray();
		}

		public static IEnumerable<NPath> Delete(this IEnumerable<NPath> self)
		{
			foreach (var p in self)
				p.Delete();
			return self;
		}

		public static IEnumerable<string> InQuotes(this IEnumerable<NPath> self, SlashMode forward = SlashMode.Native)
		{
			return self.Select(p => p.InQuotes(forward));
		}

		public static NPath ToNPath(this string path)
		{
			return new NPath(path);
		}
	}

	public enum SlashMode
	{
		Native,
		Forward,
		Backward
	}

	public enum DeleteMode
	{
		Normal,
		Soft
	}
}

namespace P4Nano
{
	public class ArrayFieldCollection : IEnumerable<ArrayField>
	{
		readonly Record _record;

		public ArrayFieldCollection(Record record) { _record = record; }

		public IEnumerable<string> ToStrings(int indent)
		{
			var indentText = new string(' ', indent * 4);
			foreach (var arrayField in this)
			{
				yield return indentText + arrayField.Name + ":";
				foreach (var str in arrayField.ToStrings(indent + 1))
				{
					yield return str;
				}
			}
		}

		public IEnumerable<string> ToStrings() { return ToStrings(0); }

		public override string ToString()
		{
			var sb = new StringBuilder();
			foreach (var str in ToStrings())
			{
				sb.AppendLine(str);
			}
			return sb.ToString();
		}

		public ArrayField this[string key] { get { return new ArrayField(_record, key); } }

		public void Set(string key, params object[] values) { Set(key, (IEnumerable<object>)values); }
		public void Set(string key, IEnumerable<object> values) { new ArrayField(_record, key).Set(values); }

		public IEnumerator<ArrayField> GetEnumerator()
		{
			if (_record.HasItems)
			{
				var arrayFields =
					from key in _record.Items[0].Keys
					let arrayField = new ArrayField(_record, key)
					where arrayField.Any()
					select arrayField;
				foreach (var arrayField in arrayFields)
				{
					yield return arrayField;
				}
			}
		}

		IEnumerator IEnumerable.GetEnumerator() { return GetEnumerator(); }
	}

	public class TimeFieldDictionary
	{
		readonly Record _record;

		public TimeFieldDictionary(Record record) { _record = record; }

		public DateTime this[string key]
		{
			get
			{
				var value = _record[key];

				DateTime dt;
				if (DateTime.TryParse(value, out dt))
				{
					return dt;
				}

				return Utility.P4ToSystem(int.Parse(value));
			}
			set { _record[key] = Utility.SystemToP4(value).ToString(); }
		}
	}

	// this complication comes from p4's two different types of data mixed into one protocol:
	//
	//   1. filelog style output, where we have a hierarcy of records
	//   2. form style output, where we have array-fields like "View" that need collapsing
	//
	// so the ArrayField exists to translate between the two automatically.

	public class ArrayField : IList<string>
	{
		readonly IList<Record> _items;
		readonly string _key;

		public ArrayField(Record record, string key)
		{
			if (key == null) { throw new ArgumentNullException("key"); }

			_items = record.Items; // this call will auto-create the list if needed
			_key = key;
		}

		internal static string[] SplitField(string fieldValue) { return fieldValue.Replace("\r", "").TrimEnd().Split('\n'); }

		public IEnumerable<string> ToStrings(int indent)
		{
			var indentText = new string(' ', indent * 4);
			return
				from val in this
				from line in SplitField(val)
				select indentText + line;
		}

		public IEnumerable<string> ToStrings() { return ToStrings(0); }

		public override string ToString()
		{
			var sb = new StringBuilder();
			foreach (var str in ToStrings())
			{
				sb.AppendLine(str);
			}
			return sb.ToString();
		}

		public string Name { get { return _key; } }

		public void Set(IEnumerable<object> items)
		{
			var index = 0;
			foreach (var item in items)
			{
				if (_items.Count <= index)
				{
					_items.Add(new Record());
				}
				_items[index][_key] = item.ToString();
				++index;
			}

			for (; index < _items.Count; ++index)
			{
				if (!_items[index].Remove(_key))
				{
					break;
				}
			}

			CompactEnd();
		}

		public void Set(params object[] items) { Set((IEnumerable<object>)items); }

		public int IndexOf(string item)
		{
			if (item == null) { throw new ArgumentNullException("item"); }

			var index = 0;
			foreach (var val in this)
			{
				if (val == item) { return index; }
				++index;
			}
			return -1;
		}

		public void Insert(int index, string item)
		{
			InsertRange(index, WrapEnumerable(item), 1);
		}

		public void InsertRange(int index, IEnumerable<object> items)
		{
			var collection = items as ICollection<object> ?? new List<object>(items);
			InsertRange(index, collection.Select(v => v.ToString()), collection.Count);
		}

		void InsertRange(int index, IEnumerable<string> items, int itemsCount)
		{
			var oldCount = Count;
			if (index < 0 || index > oldCount) { throw new IndexOutOfRangeException(); }

			if (itemsCount > 0)
			{
				while (_items.Count < (oldCount + itemsCount))
				{
					_items.Add(new Record());
				}

				for (var i = _items.Count - 1; i >= index + itemsCount; --i)
				{
					_items[i][_key] = _items[i - itemsCount][_key];
				}

				var idst = index;
				foreach (var item in items)
				{
					_items[idst++][_key] = item;
				}
			}
		}

		public void RemoveAt(int index)
		{
			RemoveRange(index, 1);
		}

		public void RemoveRange(int index, int removeCount)
		{
			var oldCount = Count;
			if (index < 0 || removeCount < 0 || (index + removeCount) > oldCount) { throw new IndexOutOfRangeException(); }

			if (removeCount > 0)
			{
				for (var i = index + removeCount; i < oldCount; ++i)
				{
					_items[i - removeCount][_key] = _items[i][_key];
				}

				for (var i = oldCount - removeCount; i < oldCount; ++i)
				{
					_items[i].Remove(_key);
				}

				CompactEnd();
			}
		}

		public string this[int index]
		{
			get { return _items[index][_key]; }
			set { _items[index][_key] = value; }
		}

		public void Add(string item)
		{
			if (item == null) { throw new ArgumentNullException("item"); }

			var oldCount = Count;
			if (_items.Count < (oldCount + 1))
			{
				_items.Add(new Record());
			}
			_items[oldCount][_key] = item;
		}

		public void AddRange(IEnumerable<object> items)
		{
			if (items == null) { throw new ArgumentNullException("items"); }

			foreach (var item in items)
			{
				Add(item.ToString());
			}
		}

		public void Clear() { Set(Enumerable.Empty<string>()); }
		public bool Contains(string item) { return IndexOf(item) >= 0; }

		public void CopyTo(string[] array, int arrayIndex)
		{
			foreach (var val in this)
			{
				array[arrayIndex++] = val;
			}
		}

		public int Count { get { return _items.Count(r => r.ContainsKey(_key)); } }

		public bool IsReadOnly { get { return false; } }

		public bool Remove(string item)
		{
			var index = IndexOf(item);
			if (index >= 0)
			{
				RemoveAt(index);
				return true;
			}
			return false;
		}

		public IEnumerator<string> GetEnumerator()
		{
			foreach (var record in _items)
			{
				string val;
				if (!record.TryGetValue(_key, out val)) { break; }
				yield return val;
			}
		}

		IEnumerator IEnumerable.GetEnumerator() { return GetEnumerator(); }

		void CompactEnd()
		{
			for (var i = _items.Count - 1; i >= 0; --i)
			{
				if (_items[i].Count == 0)
				{
					_items.RemoveAt(i);
				}
			}
		}

		IEnumerable<T> WrapEnumerable<T>(T item) { yield return item; }
	}

	public static class Utility
	{
		static readonly DateTime _p4Epoch = new DateTime(1970, 1, 1);

		public static DateTime P4ToSystem(int p4Date)
		{
			var utc = _p4Epoch.AddSeconds(p4Date);
			return TimeZone.CurrentTimeZone.ToLocalTime(utc);
		}

		public static DateTime P4ToSystem(string p4Date)
		{
			return p4Date != null ? P4ToSystem(int.Parse(p4Date)) : new DateTime();
		}

		public static int SystemToP4(DateTime date)
		{
			var utc = TimeZone.CurrentTimeZone.ToUniversalTime(date);
			var ts = utc.Subtract(_p4Epoch);
			return (int)ts.TotalSeconds;
		}

		// from .net 4
		public static bool IsNullOrWhiteSpace(string value)
		{
			return value == null || value.All(char.IsWhiteSpace);
		}

		public static Regex P4ToRegex(IEnumerable<object> patterns)
		{
			var rxtext = new StringBuilder();
			var first = true;

			foreach (var line in
				from p in patterns.Select(v => v.ToString())
				where !IsNullOrWhiteSpace(p)
				select p.Trim())
			{
				if (line.StartsWith("-"))
				{
					throw new ArgumentException("Patterns cannot contain '-' exclusions");
				}

				if (Regex.IsMatch(line, @"//.*//"))
				{
					throw new ArgumentException("Pattern contains more than one '//' - accidental joining of two patterns into a single string?");
				}

				if (!first)
				{
					rxtext.Append('|');
				}
				first = false;

				rxtext.Append('^');

				for (var i = 0; i < line.Length;)
				{
					switch (line[i])
					{
						case '.':
							if (((line.Length - i) >= 3) && (line[i + 1] == '.') && (line[i + 2] == '.'))
							{
								rxtext.Append(".*");
								i += 3;
							}
							else
							{
								rxtext.Append("\\.");
								++i;
							}
							break;
						case '*':
							rxtext.Append("[^/]*");
							++i;
							break;
						case '?':
							rxtext.Append('.');
							++i;
							break;
						default:
							rxtext.Append(Regex.Escape(line.Substring(i, 1)));
							++i;
							break;
					}
				}

				rxtext.Append('$');
			}

			return new Regex(rxtext.ToString(), RegexOptions.IgnoreCase);
		}

		public static Regex P4ToRegex(string pattern)
		{
			return P4ToRegex(new[] { pattern });
		}
	}

	public class CommandArgs
	{
		public CommandArgs(IEnumerable<object> args)
		{
			PreArgs = new List<string>();
			PostArgs = new List<string>();
			var currentArgs = PreArgs;

			using (var iarg = args.Select(v => v.ToString()).GetEnumerator())
				while (iarg.MoveNext())
				{
					var arg = iarg.Current;
					if (arg == null) { continue; }

					if (currentArgs == PreArgs)
					{
						// hyphen means it's a pre arg
						if (arg.StartsWith("-"))
						{
							currentArgs.Add(arg);

							// these options each have one arg, so grab the arg too, it's not a command
							if (Regex.IsMatch(arg, @"^-[cCdHLpPQuxz]$"))
							{
								if (iarg.MoveNext())
								{
									currentArgs.Add(iarg.Current);
								}
							}
						}
						else
						{
							Command = arg;
							currentArgs = PostArgs;
						}
					}
					else
					{
						currentArgs.Add(arg);
					}
				}
		}

		public CommandArgs(string cmdLine)
			: this(cmdLine.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries)) { }

		public static CommandArgs Parse(params object[] args)
		{
			return new CommandArgs(GetArgs(args));
		}

		static IEnumerable<object> GetArgs(IEnumerable<object> args)
		{
			foreach (var arg in args)
			{
				var objects = arg as IEnumerable<object>; // posh may nest, and that's cool..
				if (objects != null)
				{
					foreach (var o in GetArgs(objects))
					{
						yield return o;
					}
				}
				else if (arg != null)
				{
					yield return arg.ToString();
				}
			}
		}

		public IList<string> PreArgs { get; private set; }
		public string Command { get; private set; }
		public IList<string> PostArgs { get; private set; }
		public IEnumerable<string> AllArgs { get { return PreArgs.Concat(new[] { Command }).Concat(PostArgs); } }

		public override string ToString()
		{
			return string.Join(" ", AllArgs.ToArray());
		}
	}

	[DebuggerDisplay("{ShortString}")]
	public class Record : Dictionary<string, string>, IEquatable<Record>, ICloneable
	{
		static readonly Regex _nameRx = new Regex(@"^(\w+?)(\d+(?:,\d+)*)$");
		static bool _cancelOnCtrlC;

		List<Record> _items;

		public Record()
			: base(StringComparer.OrdinalIgnoreCase) { }

		public Record(Record other)
			: this()
		{
			foreach (var kv in other)
			{
				Add(kv.Key, kv.Value);
			}

			if (other._items != null)
			{
				_items = new List<Record>();
				foreach (var r in other._items)
				{
					_items.Add(new Record(r));
				}
			}
		}

		// currently only works on simply formatted forms coming from p4 itself. the spec has more features, such as comments,
		// that we aren't checking for.
		public Record(string formText)
			: this()
		{
			var keyMode = true;
			string currentKey = null;
			var currentValue = new List<string>();

			using (var reader = new StringReader(formText))
			{
				for (; ; )
				{
					var line = reader.ReadLine();
					if (line == null)
					{
						break;
					}

					if (keyMode)
					{
						var match = Regex.Match(line, @"^(\w+):(?:\t(\w+))?");
						if (match.Success)
						{
							if (match.Groups[2].Success)
							{
								Add(match.Groups[1].Value, match.Groups[2].Value);
							}
							else
							{
								keyMode = false;
								currentKey = match.Groups[1].Value;
							}
						}
					}
					else if (line.Length != 0 && line[0] == '\t')
					{
						currentValue.Add(line.Substring(1));
					}
					else
					{
						Add(currentKey, string.Join("\n", currentValue.ToArray()));

						keyMode = true;
						currentKey = null;
						currentValue.Clear();
					}
				}
			}

			if (!keyMode)
			{
				Add(currentKey, string.Join("\n", currentValue.ToArray()));
			}
		}

		internal Record(BinaryReader reader)
			: this()
		{
			foreach (var kv in r_hash(reader))
			{
				var k = kv.Key;
				var v = kv.Value;
				var rec = this;

				var m = _nameRx.Match(k);
				if (m.Success)
				{
					k = m.Groups[1].Value;

					foreach (var i in
						from part in m.Groups[2].Value.Split(',')
						select int.Parse(part))
					{
						while (rec.Items.Count <= i)
						{
							rec._items.Add(new Record());
						}

						rec = rec._items[i];
					}
				}

				// special: the record may contain keys without values, which p4 uses to signify a flag. set it to 'true' to make it clear.
				if (Utility.IsNullOrWhiteSpace(v))
				{
					v = "true";
				}

				rec.Add(k, v);
			}
		}

		// global options
		public static bool CancelOnCtrlC { get { return _cancelOnCtrlC; } set { _cancelOnCtrlC = value; } }

		public IDictionary<string, string> Fields { get { return this; } }
		public TimeFieldDictionary TimeFields { get { return new TimeFieldDictionary(this); } }
		public ArrayFieldCollection ArrayFields { get { return new ArrayFieldCollection(this); } }
		public IList<Record> Items { get { return _items ?? (_items = new List<Record>()); } }
		public bool HasItems { get { return _items != null && _items.Count != 0; } }
		public bool IsInfo { get { return string.Compare(this["code"], "info", true) == 0; } }
		public bool IsFailure { get { return string.Compare(this["code"], "error", true) == 0; } }
		public bool IsError { get { return ErrorSeverity >= 3; } }
		public bool IsWarning { get { return ErrorSeverity > 0 && !IsError; } }

		public int ErrorSeverity
		{
			get
			{
				if (!IsFailure) { return 0; }

				int severity;
				int.TryParse(this["severity"], out severity);
				return severity;
			}
		}

		public string[] SortedFieldKeys
		{
			get
			{
				var keys = new string[Count];
				Keys.CopyTo(keys, 0);
				Array.Sort(keys);
				return keys;
			}
		}

		/// <summary>
		/// Call this to run a P4 command.
		/// </summary>
		/// <param name="workingDir">Working dir for P4. Necessary when relying on p4.ini or using relative local paths. Optional, defaults to .NET current dir.</param>
		/// <param name="cmdLine">The command line to send to p4.exe. Make sure to quote paths with spaces. Required.</param>
		/// <param name="input">An input record to send in to a command that takes an input form, such as 'client -i'. Optional.</param>
		/// <param name="lazy">Controls whether the enumerable is lazily evaluated or not. True means minimal memory usage, immediate results and best performance, but
		/// also puts a burden on the client of needing to consume the entire thing to guarantee operations like 'sync' finish. Optional, defaults to false.</param>
		/// <returns>All results from P4, reprocessed into Record objects</returns>
		public static IEnumerable<Record> Run(string workingDir, string cmdLine, Record input, bool lazy)
		{
			var records = RunLazy(workingDir, cmdLine, input);
			if (!lazy)
			{
				records = records.ToList();
			}

			return records;
		}

		public static IEnumerable<Record> Run(string workingDir, string cmdLine, Record input)
		{ return Run(workingDir, cmdLine, input, false); }
		public static IEnumerable<Record> Run(string workingDir, string cmdLine, bool lazy)
		{ return Run(workingDir, cmdLine, null, lazy); }
		public static IEnumerable<Record> Run(string workingDir, string cmdLine)
		{ return Run(workingDir, cmdLine, null, false); }
		public static IEnumerable<Record> Run(string cmdLine, Record input, bool lazy)
		{ return Run(null, cmdLine, input, lazy); }
		public static IEnumerable<Record> Run(string cmdLine, Record input)
		{ return Run(null, cmdLine, input, false); }
		public static IEnumerable<Record> Run(string cmdLine, bool lazy)
        { return Run(null, cmdLine, null, lazy); }
        public static IEnumerable<Record> Run(string cmdLine)
        { return Run(null, cmdLine, null, false); }

        static IEnumerable<Record> RunLazy(string workingDir, string cmdLine, Record input)
        {
            return new Reader(workingDir, cmdLine, input).Run();
        }

        public string ShortString
        {
            get
            {
                const int maxFields = 10, maxFieldLen = 50;

                var kv = new List<string>(Keys);
                kv.Sort();
                if (kv.Count > maxFields)
                {
                    kv.RemoveRange(maxFields, kv.Count - maxFields);
                }

                for (var i = 0; i < kv.Count; ++i)
                {
                    var k = kv[i];
                    var v = this[k];
                    if (v.Length > maxFieldLen) { v = v.Substring(0, maxFieldLen - 3) + "..."; }
                    kv[i] = k + "=" + v;
                }

                var fields = string.Join(", ", kv.ToArray());
                if (Count > maxFields) { fields += ", ..."; }
                if (_items != null && _items.Count > 0) { fields += " (+" + _items.Count + " items)"; }

                return fields;
            }
        }

        // this is really just to have a familiar face. for submitting a form to p4,
        // send the Record through the "input" field of Run().
        public string ToFormString()
        {
            var sb = new StringBuilder();

            foreach (var kv in this.Where(kv => !ShouldSkipField(kv.Key)))
            {
                if (kv.Value.Contains("\n"))
                {
                    sb.AppendLine(kv.Key + ":");
                    foreach (var line in ArrayField.SplitField(kv.Value))
                    {
                        sb.AppendLine("\t" + line);
                    }
                }
                else
                {
                    sb.AppendLine(kv.Key + ":\t" + kv.Value);
                }
                sb.AppendLine();
            }

            foreach (var arrayField in ArrayFields)
            {
                sb.AppendLine(arrayField.Name + ":");
                foreach (var entry in arrayField)
                {
                    sb.AppendLine("\t" + entry);
                }
                sb.AppendLine();
            }
            return sb.ToString();
        }

        public IEnumerable<string> ToStrings(int indent)
        {
            var indentText = new string(' ', indent * 4);
            foreach (var kv in this)
            {
                var first = true;
                foreach (var line in ArrayField.SplitField(kv.Value))
                {
                    if (first)
                    {
                        yield return indentText + kv.Key + " = " + line;
                        first = false;
                    }
                    else
                    {
                        yield return indentText + new string(' ', kv.Key.Length + 3) + line;
                    }
                }
            }

            if (_items != null)
            {
                var index = 0;
                foreach (var record in _items)
                {
                    yield return indentText + "  [" + index++ + "]";
                    foreach (var str in record.ToStrings(indent + 1))
                    {
                        yield return str;
                    }
                }
            }
        }

        public IEnumerable<string> ToStrings() { return ToStrings(0); }

        public override string ToString()
        {
            var sb = new StringBuilder();
            foreach (var str in ToStrings())
            {
                sb.AppendLine(str);
            }
            return sb.ToString();
        }

        public bool Equals(Record other)
        {
            if (ReferenceEquals(null, other)) { return false; }
            if (ReferenceEquals(this, other)) { return true; }

            if (Count != other.Count) { return false; }

            var itemCount = _items != null ? _items.Count : 0;
            var otherItemCount = other._items != null ? other._items.Count : 0;
            if (itemCount != otherItemCount) { return false; }

            foreach (var kv in this)
            {
                string otherValue;
                if (!other.TryGetValue(kv.Key, out otherValue) || !Equals(kv.Value, otherValue)) { return false; }
            }

            for (var i = 0; i < itemCount; ++i)
            {
                // ReSharper disable PossibleNullReferenceException
                if (!_items[i].Equals(other._items[i])) { return false; }
                // ReSharper restore PossibleNullReferenceException
            }

            return true;
        }

        public override bool Equals(object obj)
        {
            if (ReferenceEquals(this, obj)) { return true; }

            var other = obj as Record;
            return !ReferenceEquals(other, null) && Equals(other);
        }

        public override int GetHashCode()
        {
            var hash = SortedFieldKeys.Aggregate(0,
                (current, k) => current ^ (Comparer.GetHashCode(k) ^ this[k].GetHashCode()));

            // ReSharper disable NonReadonlyFieldInGetHashCode
            if (_items != null)
            {
                hash = _items.Aggregate(hash, (current, r) => current ^ r.GetHashCode());
            }
            // ReSharper restore NonReadonlyFieldInGetHashCode

            return hash;
        }

        public static bool operator ==(Record left, Record right) { return Equals(left, right); }
        public static bool operator !=(Record left, Record right) { return !Equals(left, right); }

        public Record Clone() { return new Record(this); }
        object ICloneable.Clone() { return Clone(); }

        static bool ShouldSkipField(string fieldName)
        {
            // add to this list as needed
            return string.Compare(fieldName, "code", true) == 0;
        }

        void Write(BinaryWriter writer)
        {
            writer.Write(MARSHAL_MAJOR);
            writer.Write(MARSHAL_MINOR);

            // only support one level of depth for forms
            var oldCount = Count;
            if (_items != null)
            {
                foreach (var record in _items)
                {
                    oldCount += record.Count;
                    if (record._items != null && record._items.Count > 0)
                    {
                        throw new ApplicationException("Only one level of nesting is supported for forms sent to Perforce");
                    }
                }
            }

            w_hash(GetHashStream(), oldCount, writer);
        }

        IEnumerable<KeyValuePair<string, string>> GetHashStream()
        {
            foreach (var kv in this.Where(kv => !ShouldSkipField(kv.Key)))
            {
                yield return kv;
            }

            if (_items != null && _items.Count > 0)
            {
                foreach (var k in _items[0].Keys)
                {
                    var index = 0;
                    foreach (var record in _items)
                    {
                        string v;
                        if (!record.TryGetValue(k, out v)) { break; }

                        yield return new KeyValuePair<string, string>(k + index++, v);
                    }
                }
            }
        }

        #region Reader

        sealed class Reader
        {
            readonly object _p4LockObject = new object();
            readonly ManualResetEvent _cancelRequested = new ManualResetEvent(false);
            readonly List<Record> _records = new List<Record>();
            readonly CommandArgs _commandArgs;

            Process _p4;
            int _finishedCount;

#if DEBUG_SINGLE_RECORD_STREAM
			const int _recordBufferSize = 1;
#else
            const int _recordBufferSize = 1000;
#endif

            public Reader(string workingDir, string cmdLine, Record input)
            {
                if (cmdLine == null) { throw new ArgumentNullException("cmdLine"); }

                // grab command in case we need to do special parsing
                _commandArgs = new CommandArgs(cmdLine);

                // fire up process
                _p4 = Process.Start(new ProcessStartInfo("p4", "-R " + cmdLine)
                {
                    // note that stdin must always be redirected, otherwise we'll get a hang instead of an error if
                    // someone does "client -i" without an input record.

                    WorkingDirectory = workingDir,
                    CreateNoWindow = true,
                    UseShellExecute = false,
                    RedirectStandardError = true,
                    RedirectStandardOutput = true,
                    RedirectStandardInput = true
                });

                if (_cancelOnCtrlC)
                {
                    Console.CancelKeyPress += Console_CancelKeyPress;
                }

                // start readers

                new Thread(StderrReader) { Name = "p4nano.StderrReader" }.Start();
                new Thread(StdoutReader) { Name = "p4nano.StdoutReader" }.Start();

                // write any input requested

                lock (_p4LockObject)
                {
                    if (input != null)
                    {
                        input.Write(new BinaryWriter(_p4.StandardInput.BaseStream));
                    }

                    _p4.StandardInput.Close();
                }
            }

            public IEnumerable<Record> Run()
            {
                try
                {
                    for (; ; )
                    {
                        var recordSet = GetNextRecordSet();
                        if (recordSet == null)
                        {
                            // null return means end of stream or cancel
                            break;
                        }

                        foreach (var record in recordSet)
                        {
                            yield return record;
                        }
                    }
                }
                finally
                {
                    // this is called on enumerator disposal or if an exception occurs during iteration. best
                    // place to kill the process if it wasn't done already.
                    Cancel();
                }
            }

            void Cancel()
            {
                // ideally this would send a ctrl-c but can't figure that out. killing the process will work
                // but will prevent p4.exe from cleaning up after itself, so may get temp files laying around.
                // http://stackoverflow.com/questions/297615/stuck-on-generateconsolectrlevent-in-c-with-console-apps

                lock (_p4LockObject)
                {
                    if (_p4 != null && !_p4.HasExited)
                    {
                        try { _p4.Kill(); }
                        catch { }
                    }
                }

                _cancelRequested.Set();
            }

            IEnumerable<Record> GetNextRecordSet()
            {
                for (; ; )
                {
                    lock (_records)
                    {
                        if (_records.Count > 0)
                        {
                            var records = _records.ToArray();
                            _records.Clear();
                            return records;
                        }

                        if (_finishedCount == 2)
                        {
                            return null;
                        }
                    }

                    // give time for records to be retrieved by p4.exe or read by worker threads
                    Thread.Sleep(1);
                }
            }

            void StdoutReader() { Exec(StdoutReaderExec); }

            void StdoutReaderExec()
            {
                var stdout = _p4.StandardOutput.BaseStream;

                // special processing first
                if (_commandArgs.Command == "set")
                {
                    var record = new Record();
                    record["help"] = "Check the Items array for records"; // too easy to test "p4n set" and get (apparently) nothing back and forget to route through tostring to see the items

                    var reader = new StreamReader(stdout);
                    string line;
                    while ((line = reader.ReadLine()) != null)
                    {
                        var m = Regex.Match(line, @"(.*)=(.*?)(?:\s+\(([^)]*)\))?$");
                        var entry = new Record();
                        entry["var"] = m.Groups[1].Value.Trim();
                        entry["value"] = m.Groups[2].Value.Trim();
                        if (m.Groups[3].Success)
                        {
                            entry["where"] = m.Groups[3].Value.Trim();
                        }
                        record.Items.Add(entry);
                    }

                    lock (_records)
                    {
                        _records.Add(record);
                    }

                    return;
                }

                for (; ; )
                {
                    var recordMajor = stdout.ReadByte();
                    var recordMinor = stdout.ReadByte();

                    // -1 means end of stream (process exit)
                    if (recordMajor < 0)
                    {
                        return;
                    }

                    // only check major version, that should be the only time a format change happens we might care about
                    if (recordMajor != MARSHAL_MAJOR)
                    {
                        throw new ApplicationException(
                            string.Format("Unsupported version {0}.{1}", recordMajor, recordMinor));
                    }

                    // read the next record
                    var record = new Record(new BinaryReader(stdout));

                    // special processing
                    if (_commandArgs.Command == "change" && _commandArgs.PostArgs.Contains("-i") && record.IsInfo && !record.ContainsKey("change"))
                    {
                        var g = Regex.Match(record["data"], @"Change (\d+) created").Groups[1];
                        if (g.Success)
                        {
                            record["change"] = g.Value;
                        }
                    }

                    // loop until we have room to insert the next record
                    for (; ; )
                    {
                        lock (_records)
                        {
                            if (_records.Count < _recordBufferSize)
                            {
                                _records.Add(record);
                                break;
                            }
                        }

                        // give time for records to be pulled by enumerator
                        if (_cancelRequested.WaitOne(1))
                        {
                            return;
                        }
                    }
                }
            }

            void StderrReader() { Exec(StderrReaderExec); }

            void StderrReaderExec()
            {
                var sb = new StringBuilder();
                for (; ; )
                {
                    var c = _p4.StandardError.Read();

                    // -1 means end of stream (process exit)
                    if (c < 0)
                    {
                        if (sb.Length > 0)
                        {
                            var record = new Record();
                            record["code"] = "error";
                            record["data"] = sb.ToString();
                            record["severity"] = "3";

                            lock (_records)
                            {
                                _records.Add(record);
                            }
                        }

                        return;
                    }

                    sb.Append((char)c);
                }
            }

            delegate void Action();

            void Exec(Action reader)
            {
                try
                {
                    reader();
                }
                finally
                {
                    if (Interlocked.Increment(ref _finishedCount) == 2)
                    {
                        Console.CancelKeyPress -= Console_CancelKeyPress;

                        lock (_p4LockObject)
                        {
                            // give it a little bit to finish cleaning up if exiting normally
                            if (!_p4.WaitForExit(100))
                            {
                                try { _p4.Kill(); }
                                catch { }
                            }

                            // release system handle, don't leave it for finalizer
                            _p4.Dispose();
                            _p4 = null;
                        }
                    }
                }
            }

            void Console_CancelKeyPress(object sender, ConsoleCancelEventArgs e)
            {
                Cancel();
            }
        }

        #endregion

        #region Ruby Parser

        // adapted from http://ruby-doc.org/doxygen/1.8.4/marshal_8c-source.html

        // ReSharper disable InconsistentNaming
        const byte MARSHAL_MAJOR = 4;
        const byte MARSHAL_MINOR = 8;
        const byte TYPE_FIXNUM = (byte)'i';
        const byte TYPE_STRING = (byte)'"';
        const byte TYPE_HASH = (byte)'{';
        // ReSharper restore InconsistentNaming

        static int r_long(BinaryReader reader)
        {
            int x;
            int c = (char)reader.ReadByte();
            int i;

            if (c == 0) { return 0; }
            if (c > 0)
            {
                if (4 < c && c < 128) { return c - 5; }
                if (c > sizeof(int)) { throw new ApplicationException("Int too big: " + c); }
                x = 0;
                for (i = 0; i < c; i++)
                {
                    x |= reader.ReadByte() << (8 * i);
                }
            }
            else
            {
                if (-129 < c && c < -4)
                {
                    return c + 5;
                }
                c = -c;
                if (c > sizeof(int)) { throw new ApplicationException("Int too big: " + c); }
                x = -1;
                for (i = 0; i < c; i++)
                {
                    x &= ~(0xff << (8 * i));
                    x |= reader.ReadByte() << (8 * i);
                }
            }
            return x;
        }

        static void w_long(int x, BinaryWriter writer)
        {
            if (x == 0)
            {
                writer.Write((byte)0);
                return;
            }
            if (0 < x && x < 123)
            {
                writer.Write((byte)(x + 5));
                return;
            }
            if (-124 < x && x < 0)
            {
                writer.Write((byte)((x - 5) & 0xff));
                return;
            }

            var buf = new byte[sizeof(int) + 1];
            byte i;
            for (i = 1; i < sizeof(int) + 1; i++)
            {
                buf[i] = (byte)(x & 0xff);
                x = x >> 8;
                if (x == 0)
                {
                    buf[0] = i;
                    break;
                }
                if (x == -1)
                {
                    buf[0] = (byte)-i;
                    break;
                }
            }
            writer.Write(buf, 0, i + 1);
        }

        static string r_object_as_string(BinaryReader reader)
        {
            var c = reader.ReadByte();
            switch (c)
            {
                case TYPE_FIXNUM:
                    return r_long(reader).ToString();

                case TYPE_STRING:
                    return Encoding.ASCII.GetString(reader.ReadBytes(r_long(reader)));

                default: throw new ApplicationException(string.Format("Unrecognized type: {0} ({1})", c, (int)c));
            }
        }

        // ReSharper disable UnusedMember.Local
        static void w_object(int i, BinaryWriter writer)
        {
            writer.Write(TYPE_FIXNUM);
            w_long(i, writer);
        }
        // ReSharper restore UnusedMember.Local

        static void w_object(string s, BinaryWriter writer)
        {
            writer.Write(TYPE_STRING);
            var b = Encoding.ASCII.GetBytes(s);
            w_long(b.Length, writer);
            writer.Write(b);
        }

        static IEnumerable<KeyValuePair<string, string>> r_hash(BinaryReader reader)
        {
            // 'p4 -R' does Ruby dictionaries very simply - a set of records, each containing a hashtable where
            // each entry is a string key and a string or int value. we use Ruby output instead of -Ztag because
            // the "..." output can have ambiguity when a text description field is involved.

            // should contain a single hash
            var hashType = reader.ReadByte();
            if (hashType != TYPE_HASH)
            {
                throw new ApplicationException(string.Format("Unrecognized type: {0} ({1})", (char)hashType, (int)hashType));
            }

            // reprocess into the format we want as we go
            for (var hashCount = r_long(reader); hashCount > 0; --hashCount)
            {
                var k = r_object_as_string(reader);
                var v = r_object_as_string(reader);
                yield return new KeyValuePair<string, string>(k, v);
            }
        }

        static void w_hash(IEnumerable<KeyValuePair<string, string>> kvs, int count, BinaryWriter writer)
        {
            writer.Write(TYPE_HASH);
            w_long(count, writer);
            foreach (var kv in kvs)
            {
                w_object(kv.Key, writer);
                w_object(kv.Value, writer);
            }
        }

        #endregion
    }
}

namespace Microsoft.Collections.Extensions
{
    /// <summary>
    /// A MultiValueDictionary can be viewed as a <see cref="IDictionary" /> that allows multiple 
    /// values for any given unique key. While the MultiValueDictionary API is 
    /// mostly the same as that of a regular <see cref="IDictionary" />, there is a distinction
    /// in that getting the value for a key returns a <see cref="IReadOnlyCollection{TValue}" /> of values
    /// rather than a single value associated with that key. Additionally, 
    /// there is functionality to allow adding or removing more than a single
    /// value at once. 
    /// 
    /// The MultiValueDictionary can also be viewed as a IReadOnlyDictionary&lt;TKey,IReadOnlyCollection&lt;TValue&gt;t&gt;
    /// where the <see cref="IReadOnlyCollection{TValue}" /> is abstracted from the view of the programmer.
    /// 
    /// For a read-only MultiValueDictionary, see <see cref="System.Linq.ILookup{TKey, TValue}" />.
    /// </summary>
    /// <typeparam name="TKey">The type of the key.</typeparam>
    /// <typeparam name="TValue">The type of the value.</typeparam>
    public class MultiValueDictionary<TKey, TValue> :
        IReadOnlyDictionary<TKey, IReadOnlyCollection<TValue>>
    {
        #region Variables
        /*======================================================================
        ** Variables
        ======================================================================*/

        /// <summary>
        /// The private dictionary that this class effectively wraps around
        /// </summary>
        private readonly Dictionary<TKey, InnerCollectionView> _dictionary;

        /// <summary>
        /// The function to construct a new <see cref="ICollection{TValue}"/>
        /// </summary>
        /// <returns></returns>
        private Func<ICollection<TValue>> NewCollectionFactory = () => new List<TValue>();

        /// <summary>
        /// The current version of this MultiValueDictionary used to determine MultiValueDictionary modification
        /// during enumeration
        /// </summary>
        private int _version;

        #endregion

        #region Constructors
        /*======================================================================
        ** Constructors
        ======================================================================*/

        /// <summary>
        /// Initializes a new instance of the <see cref="MultiValueDictionary{TKey, TValue}" /> 
        /// class that is empty, has the default initial capacity, and uses the default
        /// <see cref="IEqualityComparer{TKey}" /> for <typeparamref name="TKey"/>.
        /// </summary>
        public MultiValueDictionary()
        {
            _dictionary = new Dictionary<TKey, InnerCollectionView>();
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="MultiValueDictionary{TKey, TValue}" /> class that is 
        /// empty, has the specified initial capacity, and uses the default <see cref="IEqualityComparer{TKey}"/>
        /// for <typeparamref name="TKey"/>.
        /// </summary>
        /// <param name="capacity">Initial number of keys that the <see cref="MultiValueDictionary{TKey, TValue}" /> will allocate space for</param>
        /// <exception cref="ArgumentOutOfRangeException">capacity must be >= 0</exception>
        public MultiValueDictionary(int capacity)
        {
            if (capacity < 0)
                throw new ArgumentOutOfRangeException(nameof(capacity), /*Strings.*/"ArgumentOutOfRange_NeedNonNegNum");
            _dictionary = new Dictionary<TKey, InnerCollectionView>(capacity);
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="MultiValueDictionary{TKey, TValue}" /> class 
        /// that is empty, has the default initial capacity, and uses the 
        /// specified <see cref="IEqualityComparer{TKey}" />.
        /// </summary>
        /// <param name="comparer">Specified comparer to use for the <typeparamref name="TKey"/>s</param>
        /// <remarks>If <paramref name="comparer"/> is set to null, then the default <see cref="IEqualityComparer" /> for <typeparamref name="TKey"/> is used.</remarks>
        public MultiValueDictionary(IEqualityComparer<TKey> comparer)
        {
            _dictionary = new Dictionary<TKey, InnerCollectionView>(comparer);
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="MultiValueDictionary{TKey, TValue}" /> class 
        /// that is empty, has the specified initial capacity, and uses the 
        /// specified <see cref="IEqualityComparer{TKey}" />.
        /// </summary>
        /// <param name="capacity">Initial number of keys that the <see cref="MultiValueDictionary{TKey, TValue}" /> will allocate space for</param>
        /// <param name="comparer">Specified comparer to use for the <typeparamref name="TKey"/>s</param>
        /// <exception cref="ArgumentOutOfRangeException">Capacity must be >= 0</exception>
        /// <remarks>If <paramref name="comparer"/> is set to null, then the default <see cref="IEqualityComparer" /> for <typeparamref name="TKey"/> is used.</remarks>
        public MultiValueDictionary(int capacity, IEqualityComparer<TKey> comparer)
        {
            if (capacity < 0)
                throw new ArgumentOutOfRangeException(nameof(capacity), /*Strings.*/"ArgumentOutOfRange_NeedNonNegNum");
            _dictionary = new Dictionary<TKey, InnerCollectionView>(capacity, comparer);
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="MultiValueDictionary{TKey, TValue}" /> class that contains 
        /// elements copied from the specified IEnumerable&lt;KeyValuePair&lt;TKey, IReadOnlyCollection&lt;TValue&gt;&gt;&gt; and uses the 
        /// default <see cref="IEqualityComparer{TKey}" /> for the <typeparamref name="TKey"/> type.
        /// </summary>
        /// <param name="enumerable">IEnumerable to copy elements into this from</param>
        /// <exception cref="ArgumentNullException">enumerable must be non-null</exception>
        public MultiValueDictionary(IEnumerable<KeyValuePair<TKey, IReadOnlyCollection<TValue>>> enumerable)
            : this(enumerable, null)
        { }

        /// <summary>
        /// Initializes a new instance of the <see cref="MultiValueDictionary{TKey, TValue}" /> class that contains 
        /// elements copied from the specified IEnumerable&lt;KeyValuePair&lt;TKey, IReadOnlyCollection&lt;TValue&gt;&gt;&gt; and uses the 
        /// specified <see cref="IEqualityComparer{TKey}" />.
        /// </summary>
        /// <param name="enumerable">IEnumerable to copy elements into this from</param>
        /// <param name="comparer">Specified comparer to use for the <typeparamref name="TKey"/>s</param>
        /// <exception cref="ArgumentNullException">enumerable must be non-null</exception>
        /// <remarks>If <paramref name="comparer"/> is set to null, then the default <see cref="IEqualityComparer" /> for <typeparamref name="TKey"/> is used.</remarks>
        public MultiValueDictionary(IEnumerable<KeyValuePair<TKey, IReadOnlyCollection<TValue>>> enumerable, IEqualityComparer<TKey> comparer)
        {
            if (enumerable == null)
                throw new ArgumentNullException(nameof(enumerable));

            _dictionary = new Dictionary<TKey, InnerCollectionView>(comparer);
            foreach (var pair in enumerable)
                AddRange(pair.Key, pair.Value);
        }

        #endregion

        #region Static Factories
        /*======================================================================
        ** Static Factories
        ======================================================================*/

        /// <summary>
        /// Creates a new new instance of the <see cref="MultiValueDictionary{TKey, TValue}" /> 
        /// class that is empty, has the default initial capacity, and uses the default
        /// <see cref="IEqualityComparer{TKey}" /> for <typeparamref name="TKey"/>. The 
        /// internal dictionary will use instances of the <typeparamref name="TValueCollection"/>
        /// class as its collection type.
        /// </summary>
        /// <typeparam name="TValueCollection">
        /// The collection type that this <see cref="MultiValueDictionary{TKey, TValue}" />
        /// will contain in its internal dictionary.
        /// </typeparam>
        /// <returns>A new <see cref="MultiValueDictionary{TKey, TValue}" /> with the specified
        /// parameters.</returns>
        /// <exception cref="InvalidOperationException"><typeparamref name="TValueCollection"/> must not have
        /// IsReadOnly set to true by default.</exception>
        /// <remarks>
        /// Note that <typeparamref name="TValueCollection"/> must implement <see cref="ICollection{TValue}"/>
        /// in addition to being constructable through new(). The collection returned from the constructor
        /// must also not have IsReadOnly set to True by default.
        /// </remarks>
        public static MultiValueDictionary<TKey, TValue> Create<TValueCollection>()
            where TValueCollection : ICollection<TValue>, new()
        {
            if (new TValueCollection().IsReadOnly)
                throw new InvalidOperationException(/*Strings.*/"Create_TValueCollectionReadOnly");

            return new MultiValueDictionary<TKey, TValue>
            {
                NewCollectionFactory = () => new TValueCollection()
            };
        }

        /// <summary>
        /// Creates a new new instance of the <see cref="MultiValueDictionary{TKey, TValue}" /> 
        /// class that is empty, has the specified initial capacity, and uses the default
        /// <see cref="IEqualityComparer{TKey}" /> for <typeparamref name="TKey"/>. The 
        /// internal dictionary will use instances of the <typeparamref name="TValueCollection"/>
        /// class as its collection type.
        /// </summary>
        /// <typeparam name="TValueCollection">
        /// The collection type that this <see cref="MultiValueDictionary{TKey, TValue}" />
        /// will contain in its internal dictionary.
        /// </typeparam>
        /// <param name="capacity">Initial number of keys that the <see cref="MultiValueDictionary{TKey, TValue}" /> will allocate space for</param>
        /// <returns>A new <see cref="MultiValueDictionary{TKey, TValue}" /> with the specified
        /// parameters.</returns>
        /// <exception cref="ArgumentOutOfRangeException">Capacity must be >= 0</exception>
        /// <exception cref="InvalidOperationException"><typeparamref name="TValueCollection"/> must not have
        /// IsReadOnly set to true by default.</exception>
        /// <remarks>
        /// Note that <typeparamref name="TValueCollection"/> must implement <see cref="ICollection{TValue}"/>
        /// in addition to being constructable through new(). The collection returned from the constructor
        /// must also not have IsReadOnly set to True by default.
        /// </remarks>
        public static MultiValueDictionary<TKey, TValue> Create<TValueCollection>(int capacity)
            where TValueCollection : ICollection<TValue>, new()
        {
            if (capacity < 0)
                throw new ArgumentOutOfRangeException(nameof(capacity), /*Strings.*/"ArgumentOutOfRange_NeedNonNegNum");
            if (new TValueCollection().IsReadOnly)
                throw new InvalidOperationException(/*Strings.*/"Create_TValueCollectionReadOnly");

            return new MultiValueDictionary<TKey, TValue>(capacity)
            {
                NewCollectionFactory = () => new TValueCollection()
            };
        }

        /// <summary>
        /// Creates a new new instance of the <see cref="MultiValueDictionary{TKey, TValue}" /> 
        /// class that is empty, has the default initial capacity, and uses the specified
        /// <see cref="IEqualityComparer{TKey}" /> for <typeparamref name="TKey"/>. The 
        /// internal dictionary will use instances of the <typeparamref name="TValueCollection"/>
        /// class as its collection type.
        /// </summary>
        /// <typeparam name="TValueCollection">
        /// The collection type that this <see cref="MultiValueDictionary{TKey, TValue}" />
        /// will contain in its internal dictionary.
        /// </typeparam>
        /// <param name="comparer">Specified comparer to use for the <typeparamref name="TKey"/>s</param>
        /// <exception cref="InvalidOperationException"><typeparamref name="TValueCollection"/> must not have
        /// IsReadOnly set to true by default.</exception>
        /// <returns>A new <see cref="MultiValueDictionary{TKey, TValue}" /> with the specified
        /// parameters.</returns>
        /// <remarks>If <paramref name="comparer"/> is set to null, then the default <see cref="IEqualityComparer" /> for <typeparamref name="TKey"/> is used.</remarks>
        /// <remarks>
        /// Note that <typeparamref name="TValueCollection"/> must implement <see cref="ICollection{TValue}"/>
        /// in addition to being constructable through new(). The collection returned from the constructor
        /// must also not have IsReadOnly set to True by default.
        /// </remarks>
        public static MultiValueDictionary<TKey, TValue> Create<TValueCollection>(IEqualityComparer<TKey> comparer)
            where TValueCollection : ICollection<TValue>, new()
        {
            if (new TValueCollection().IsReadOnly)
                throw new InvalidOperationException(/*Strings.*/"Create_TValueCollectionReadOnly");

            return new MultiValueDictionary<TKey, TValue>(comparer)
            {
                NewCollectionFactory = () => new TValueCollection()
            };
        }

        /// <summary>
        /// Creates a new new instance of the <see cref="MultiValueDictionary{TKey, TValue}" /> 
        /// class that is empty, has the specified initial capacity, and uses the specified
        /// <see cref="IEqualityComparer{TKey}" /> for <typeparamref name="TKey"/>. The 
        /// internal dictionary will use instances of the <typeparamref name="TValueCollection"/>
        /// class as its collection type.
        /// </summary>
        /// <typeparam name="TValueCollection">
        /// The collection type that this <see cref="MultiValueDictionary{TKey, TValue}" />
        /// will contain in its internal dictionary.
        /// </typeparam>
        /// <param name="capacity">Initial number of keys that the <see cref="MultiValueDictionary{TKey, TValue}" /> will allocate space for</param>
        /// <param name="comparer">Specified comparer to use for the <typeparamref name="TKey"/>s</param>
        /// <returns>A new <see cref="MultiValueDictionary{TKey, TValue}" /> with the specified
        /// parameters.</returns>
        /// <exception cref="InvalidOperationException"><typeparamref name="TValueCollection"/> must not have
        /// IsReadOnly set to true by default.</exception>
        /// <exception cref="ArgumentOutOfRangeException">Capacity must be >= 0</exception>
        /// <remarks>If <paramref name="comparer"/> is set to null, then the default <see cref="IEqualityComparer" /> for <typeparamref name="TKey"/> is used.</remarks>
        /// <remarks>
        /// Note that <typeparamref name="TValueCollection"/> must implement <see cref="ICollection{TValue}"/>
        /// in addition to being constructable through new(). The collection returned from the constructor
        /// must also not have IsReadOnly set to True by default.
        /// </remarks>
        public static MultiValueDictionary<TKey, TValue> Create<TValueCollection>(int capacity, IEqualityComparer<TKey> comparer)
            where TValueCollection : ICollection<TValue>, new()
        {
            if (capacity < 0)
                throw new ArgumentOutOfRangeException(nameof(capacity), /*Strings.*/"ArgumentOutOfRange_NeedNonNegNum");
            if (new TValueCollection().IsReadOnly)
                throw new InvalidOperationException(/*Strings.*/"Create_TValueCollectionReadOnly");

            return new MultiValueDictionary<TKey, TValue>(capacity, comparer)
            {
                NewCollectionFactory = () => new TValueCollection()
            };
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="MultiValueDictionary{TKey, TValue}" /> class that contains 
        /// elements copied from the specified IEnumerable&lt;KeyValuePair&lt;TKey, IReadOnlyCollection&lt;TValue&gt;&gt;&gt;
        /// and uses the default <see cref="IEqualityComparer{TKey}" /> for the <typeparamref name="TKey"/> type.
        /// The internal dictionary will use instances of the <typeparamref name="TValueCollection"/>
        /// class as its collection type.
        /// </summary>
        /// <typeparam name="TValueCollection">
        /// The collection type that this <see cref="MultiValueDictionary{TKey, TValue}" />
        /// will contain in its internal dictionary.
        /// </typeparam>
        /// <param name="enumerable">IEnumerable to copy elements into this from</param>
        /// <returns>A new <see cref="MultiValueDictionary{TKey, TValue}" /> with the specified
        /// parameters.</returns>
        /// <exception cref="InvalidOperationException"><typeparamref name="TValueCollection"/> must not have
        /// IsReadOnly set to true by default.</exception>
        /// <exception cref="ArgumentNullException">enumerable must be non-null</exception>
        /// <remarks>
        /// Note that <typeparamref name="TValueCollection"/> must implement <see cref="ICollection{TValue}"/>
        /// in addition to being constructable through new(). The collection returned from the constructor
        /// must also not have IsReadOnly set to True by default.
        /// </remarks>
        public static MultiValueDictionary<TKey, TValue> Create<TValueCollection>(IEnumerable<KeyValuePair<TKey, IReadOnlyCollection<TValue>>> enumerable)
            where TValueCollection : ICollection<TValue>, new()
        {
            if (enumerable == null)
                throw new ArgumentNullException(nameof(enumerable));
            if (new TValueCollection().IsReadOnly)
                throw new InvalidOperationException(/*Strings.*/"Create_TValueCollectionReadOnly");

            var multiValueDictionary = new MultiValueDictionary<TKey, TValue>
            {
                NewCollectionFactory = () => new TValueCollection()
            };
            foreach (var pair in enumerable)
                multiValueDictionary.AddRange(pair.Key, pair.Value);
            return multiValueDictionary;
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="MultiValueDictionary{TKey, TValue}" /> class that contains 
        /// elements copied from the specified IEnumerable&lt;KeyValuePair&lt;TKey, IReadOnlyCollection&lt;TValue&gt;&gt;&gt;
        /// and uses the specified <see cref="IEqualityComparer{TKey}" /> for the <typeparamref name="TKey"/> type.
        /// The internal dictionary will use instances of the <typeparamref name="TValueCollection"/>
        /// class as its collection type.
        /// </summary>
        /// <typeparam name="TValueCollection">
        /// The collection type that this <see cref="MultiValueDictionary{TKey, TValue}" />
        /// will contain in its internal dictionary.
        /// </typeparam>
        /// <param name="enumerable">IEnumerable to copy elements into this from</param>
        /// <param name="comparer">Specified comparer to use for the <typeparamref name="TKey"/>s</param>
        /// <returns>A new <see cref="MultiValueDictionary{TKey, TValue}" /> with the specified
        /// parameters.</returns>
        /// <exception cref="InvalidOperationException"><typeparamref name="TValueCollection"/> must not have
        /// IsReadOnly set to true by default.</exception>
        /// <exception cref="ArgumentNullException">enumerable must be non-null</exception>
        /// <remarks>If <paramref name="comparer"/> is set to null, then the default <see cref="IEqualityComparer" /> for <typeparamref name="TKey"/> is used.</remarks>
        /// <remarks>
        /// Note that <typeparamref name="TValueCollection"/> must implement <see cref="ICollection{TValue}"/>
        /// in addition to being constructable through new(). The collection returned from the constructor
        /// must also not have IsReadOnly set to True by default.
        /// </remarks>
        public static MultiValueDictionary<TKey, TValue> Create<TValueCollection>(IEnumerable<KeyValuePair<TKey, IReadOnlyCollection<TValue>>> enumerable, IEqualityComparer<TKey> comparer)
            where TValueCollection : ICollection<TValue>, new()
        {
            if (enumerable == null)
                throw new ArgumentNullException(nameof(enumerable));
            if (new TValueCollection().IsReadOnly)
                throw new InvalidOperationException(/*Strings.*/"Create_TValueCollectionReadOnly");

            var multiValueDictionary = new MultiValueDictionary<TKey, TValue>(comparer)
            {
                NewCollectionFactory = () => new TValueCollection()
            };
            foreach (var pair in enumerable)
                multiValueDictionary.AddRange(pair.Key, pair.Value);
            return multiValueDictionary;
        }

        #endregion

        #region Static Factories with Func parameters
        /*======================================================================
        ** Static Factories with Func parameters
        ======================================================================*/

        /// <summary>
        /// Creates a new new instance of the <see cref="MultiValueDictionary{TKey, TValue}" /> 
        /// class that is empty, has the default initial capacity, and uses the default
        /// <see cref="IEqualityComparer{TKey}" /> for <typeparamref name="TKey"/>. The 
        /// internal dictionary will use instances of the <typeparamref name="TValueCollection"/>
        /// class as its collection type.
        /// </summary>
        /// <typeparam name="TValueCollection">
        /// The collection type that this <see cref="MultiValueDictionary{TKey, TValue}" />
        /// will contain in its internal dictionary.
        /// </typeparam>
        /// <param name="collectionFactory">A function to create a new <see cref="ICollection{TValue}"/> to use
        /// in the internal dictionary store of this <see cref="MultiValueDictionary{TKey, TValue}" />.</param>
        /// <returns>A new <see cref="MultiValueDictionary{TKey, TValue}" /> with the specified
        /// parameters.</returns>
        /// <exception cref="InvalidOperationException"><paramref name="collectionFactory"/> must create collections with
        /// IsReadOnly set to true by default.</exception>
        /// <remarks>
        /// Note that <typeparamref name="TValueCollection"/> must implement <see cref="ICollection{TValue}"/>
        /// in addition to being constructable through new(). The collection returned from the constructor
        /// must also not have IsReadOnly set to True by default.
        /// </remarks>
        public static MultiValueDictionary<TKey, TValue> Create<TValueCollection>(Func<TValueCollection> collectionFactory)
            where TValueCollection : ICollection<TValue>
        {
            if (collectionFactory().IsReadOnly)
                throw new InvalidOperationException((/*Strings.*/"Create_TValueCollectionReadOnly"));

            return new MultiValueDictionary<TKey, TValue>
            {
                NewCollectionFactory = (Func<ICollection<TValue>>)(Delegate)collectionFactory
            };
        }

        /// <summary>
        /// Creates a new new instance of the <see cref="MultiValueDictionary{TKey, TValue}" /> 
        /// class that is empty, has the specified initial capacity, and uses the default
        /// <see cref="IEqualityComparer{TKey}" /> for <typeparamref name="TKey"/>. The 
        /// internal dictionary will use instances of the <typeparamref name="TValueCollection"/>
        /// class as its collection type.
        /// </summary>
        /// <typeparam name="TValueCollection">
        /// The collection type that this <see cref="MultiValueDictionary{TKey, TValue}" />
        /// will contain in its internal dictionary.
        /// </typeparam>
        /// <param name="capacity">Initial number of keys that the <see cref="MultiValueDictionary{TKey, TValue}" /> will allocate space for</param>
        /// <param name="collectionFactory">A function to create a new <see cref="ICollection{TValue}"/> to use
        /// in the internal dictionary store of this <see cref="MultiValueDictionary{TKey, TValue}" />.</param> 
        /// <returns>A new <see cref="MultiValueDictionary{TKey, TValue}" /> with the specified
        /// parameters.</returns>
        /// <exception cref="ArgumentOutOfRangeException">Capacity must be >= 0</exception>
        /// <exception cref="InvalidOperationException"><paramref name="collectionFactory"/> must create collections with
        /// IsReadOnly set to true by default.</exception>
        /// <remarks>
        /// Note that <typeparamref name="TValueCollection"/> must implement <see cref="ICollection{TValue}"/>
        /// in addition to being constructable through new(). The collection returned from the constructor
        /// must also not have IsReadOnly set to True by default.
        /// </remarks>
        public static MultiValueDictionary<TKey, TValue> Create<TValueCollection>(int capacity, Func<TValueCollection> collectionFactory)
            where TValueCollection : ICollection<TValue>
        {
            if (capacity < 0)
                throw new ArgumentOutOfRangeException(nameof(capacity), /*Strings.*/"ArgumentOutOfRange_NeedNonNegNum");
            if (collectionFactory().IsReadOnly)
                throw new InvalidOperationException((/*Strings.*/"Create_TValueCollectionReadOnly"));

            return new MultiValueDictionary<TKey, TValue>(capacity)
            {
                NewCollectionFactory = (Func<ICollection<TValue>>)(Delegate)collectionFactory
            };
        }

        /// <summary>
        /// Creates a new new instance of the <see cref="MultiValueDictionary{TKey, TValue}" /> 
        /// class that is empty, has the default initial capacity, and uses the specified
        /// <see cref="IEqualityComparer{TKey}" /> for <typeparamref name="TKey"/>. The 
        /// internal dictionary will use instances of the <typeparamref name="TValueCollection"/>
        /// class as its collection type.
        /// </summary>
        /// <typeparam name="TValueCollection">
        /// The collection type that this <see cref="MultiValueDictionary{TKey, TValue}" />
        /// will contain in its internal dictionary.
        /// </typeparam>
        /// <param name="comparer">Specified comparer to use for the <typeparamref name="TKey"/>s</param>
        /// <param name="collectionFactory">A function to create a new <see cref="ICollection{TValue}"/> to use
        /// in the internal dictionary store of this <see cref="MultiValueDictionary{TKey, TValue}" />.</param> 
        /// <exception cref="InvalidOperationException"><paramref name="collectionFactory"/> must create collections with
        /// IsReadOnly set to true by default.</exception>
        /// <returns>A new <see cref="MultiValueDictionary{TKey, TValue}" /> with the specified
        /// parameters.</returns>
        /// <remarks>If <paramref name="comparer"/> is set to null, then the default <see cref="IEqualityComparer" /> for <typeparamref name="TKey"/> is used.</remarks>
        /// <remarks>
        /// Note that <typeparamref name="TValueCollection"/> must implement <see cref="ICollection{TValue}"/>
        /// in addition to being constructable through new(). The collection returned from the constructor
        /// must also not have IsReadOnly set to True by default.
        /// </remarks>
        public static MultiValueDictionary<TKey, TValue> Create<TValueCollection>(IEqualityComparer<TKey> comparer, Func<TValueCollection> collectionFactory)
            where TValueCollection : ICollection<TValue>
        {
            if (collectionFactory().IsReadOnly)
                throw new InvalidOperationException((/*Strings.*/"Create_TValueCollectionReadOnly"));

            return new MultiValueDictionary<TKey, TValue>(comparer)
            {
                NewCollectionFactory = (Func<ICollection<TValue>>)(Delegate)collectionFactory
            };
        }

        /// <summary>
        /// Creates a new new instance of the <see cref="MultiValueDictionary{TKey, TValue}" /> 
        /// class that is empty, has the specified initial capacity, and uses the specified
        /// <see cref="IEqualityComparer{TKey}" /> for <typeparamref name="TKey"/>. The 
        /// internal dictionary will use instances of the <typeparamref name="TValueCollection"/>
        /// class as its collection type.
        /// </summary>
        /// <typeparam name="TValueCollection">
        /// The collection type that this <see cref="MultiValueDictionary{TKey, TValue}" />
        /// will contain in its internal dictionary.
        /// </typeparam>
        /// <param name="capacity">Initial number of keys that the <see cref="MultiValueDictionary{TKey, TValue}" /> will allocate space for</param>
        /// <param name="comparer">Specified comparer to use for the <typeparamref name="TKey"/>s</param>
        /// <param name="collectionFactory">A function to create a new <see cref="ICollection{TValue}"/> to use
        /// in the internal dictionary store of this <see cref="MultiValueDictionary{TKey, TValue}" />.</param> 
        /// <returns>A new <see cref="MultiValueDictionary{TKey, TValue}" /> with the specified
        /// parameters.</returns>
        /// <exception cref="InvalidOperationException"><paramref name="collectionFactory"/> must create collections with
        /// IsReadOnly set to true by default.</exception>
        /// <exception cref="ArgumentOutOfRangeException">Capacity must be >= 0</exception>
        /// <remarks>If <paramref name="comparer"/> is set to null, then the default <see cref="IEqualityComparer" /> for <typeparamref name="TKey"/> is used.</remarks>
        /// <remarks>
        /// Note that <typeparamref name="TValueCollection"/> must implement <see cref="ICollection{TValue}"/>
        /// in addition to being constructable through new(). The collection returned from the constructor
        /// must also not have IsReadOnly set to True by default.
        /// </remarks>
        public static MultiValueDictionary<TKey, TValue> Create<TValueCollection>(int capacity, IEqualityComparer<TKey> comparer, Func<TValueCollection> collectionFactory)
            where TValueCollection : ICollection<TValue>
        {
            if (capacity < 0)
                throw new ArgumentOutOfRangeException(nameof(capacity), /*Strings.*/"ArgumentOutOfRange_NeedNonNegNum");
            if (collectionFactory().IsReadOnly)
                throw new InvalidOperationException((/*Strings.*/"Create_TValueCollectionReadOnly"));

            return new MultiValueDictionary<TKey, TValue>(capacity, comparer)
            {
                NewCollectionFactory = (Func<ICollection<TValue>>)(Delegate)collectionFactory
            };
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="MultiValueDictionary{TKey, TValue}" /> class that contains 
        /// elements copied from the specified IEnumerable&lt;KeyValuePair&lt;TKey, IReadOnlyCollection&lt;TValue&gt;&gt;&gt;
        /// and uses the default <see cref="IEqualityComparer{TKey}" /> for the <typeparamref name="TKey"/> type.
        /// The internal dictionary will use instances of the <typeparamref name="TValueCollection"/>
        /// class as its collection type.
        /// </summary>
        /// <typeparam name="TValueCollection">
        /// The collection type that this <see cref="MultiValueDictionary{TKey, TValue}" />
        /// will contain in its internal dictionary.
        /// </typeparam>
        /// <param name="enumerable">IEnumerable to copy elements into this from</param>
        /// <param name="collectionFactory">A function to create a new <see cref="ICollection{TValue}"/> to use
        /// in the internal dictionary store of this <see cref="MultiValueDictionary{TKey, TValue}" />.</param> 
        /// <returns>A new <see cref="MultiValueDictionary{TKey, TValue}" /> with the specified
        /// parameters.</returns>
        /// <exception cref="InvalidOperationException"><paramref name="collectionFactory"/> must create collections with
        /// IsReadOnly set to true by default.</exception>
        /// <exception cref="ArgumentNullException">enumerable must be non-null</exception>
        /// <remarks>
        /// Note that <typeparamref name="TValueCollection"/> must implement <see cref="ICollection{TValue}"/>
        /// in addition to being constructable through new(). The collection returned from the constructor
        /// must also not have IsReadOnly set to True by default.
        /// </remarks>
        public static MultiValueDictionary<TKey, TValue> Create<TValueCollection>(IEnumerable<KeyValuePair<TKey, IReadOnlyCollection<TValue>>> enumerable, Func<TValueCollection> collectionFactory)
            where TValueCollection : ICollection<TValue>
        {
            if (enumerable == null)
                throw new ArgumentNullException(nameof(enumerable));
            if (collectionFactory().IsReadOnly)
                throw new InvalidOperationException((/*Strings.*/"Create_TValueCollectionReadOnly"));

            var multiValueDictionary = new MultiValueDictionary<TKey, TValue>
            {
                NewCollectionFactory = (Func<ICollection<TValue>>)(Delegate)collectionFactory
            };
            foreach (var pair in enumerable)
                multiValueDictionary.AddRange(pair.Key, pair.Value);
            return multiValueDictionary;
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="MultiValueDictionary{TKey, TValue}" /> class that contains 
        /// elements copied from the specified IEnumerable&lt;KeyValuePair&lt;TKey, IReadOnlyCollection&lt;TValue&gt;&gt;&gt;
        /// and uses the specified <see cref="IEqualityComparer{TKey}" /> for the <typeparamref name="TKey"/> type.
        /// The internal dictionary will use instances of the <typeparamref name="TValueCollection"/>
        /// class as its collection type.
        /// </summary>
        /// <typeparam name="TValueCollection">
        /// The collection type that this <see cref="MultiValueDictionary{TKey, TValue}" />
        /// will contain in its internal dictionary.
        /// </typeparam>
        /// <param name="enumerable">IEnumerable to copy elements into this from</param>
        /// <param name="comparer">Specified comparer to use for the <typeparamref name="TKey"/>s</param>
        /// <param name="collectionFactory">A function to create a new <see cref="ICollection{TValue}"/> to use
        /// in the internal dictionary store of this <see cref="MultiValueDictionary{TKey, TValue}" />.</param> 
        /// <returns>A new <see cref="MultiValueDictionary{TKey, TValue}" /> with the specified
        /// parameters.</returns>
        /// <exception cref="InvalidOperationException"><paramref name="collectionFactory"/> must create collections with
        /// IsReadOnly set to true by default.</exception>
        /// <exception cref="ArgumentNullException">enumerable must be non-null</exception>
        /// <remarks>If <paramref name="comparer"/> is set to null, then the default <see cref="IEqualityComparer" /> for <typeparamref name="TKey"/> is used.</remarks>
        /// <remarks>
        /// Note that <typeparamref name="TValueCollection"/> must implement <see cref="ICollection{TValue}"/>
        /// in addition to being constructable through new(). The collection returned from the constructor
        /// must also not have IsReadOnly set to True by default.
        /// </remarks>
        public static MultiValueDictionary<TKey, TValue> Create<TValueCollection>(IEnumerable<KeyValuePair<TKey, IReadOnlyCollection<TValue>>> enumerable, IEqualityComparer<TKey> comparer, Func<TValueCollection> collectionFactory)
            where TValueCollection : ICollection<TValue>
        {
            if (enumerable == null)
                throw new ArgumentNullException(nameof(enumerable));
            if (collectionFactory().IsReadOnly)
                throw new InvalidOperationException((/*Strings.*/"Create_TValueCollectionReadOnly"));

            var multiValueDictionary = new MultiValueDictionary<TKey, TValue>(comparer)
            {
                NewCollectionFactory = (Func<ICollection<TValue>>)(Delegate)collectionFactory
            };
            foreach (var pair in enumerable)
                multiValueDictionary.AddRange(pair.Key, pair.Value);
            return multiValueDictionary;
        }

        #endregion

        #region Concrete Methods
        /*======================================================================
        ** Concrete Methods
        ======================================================================*/

        /// <summary>
        /// Adds the specified <typeparamref name="TKey"/> and <typeparamref name="TValue"/> to the <see cref="MultiValueDictionary{TKey,TValue}"/>.
        /// </summary>
        /// <param name="key">The <typeparamref name="TKey"/> of the element to add.</param>
        /// <param name="value">The <typeparamref name="TValue"/> of the element to add.</param>
        /// <exception cref="ArgumentNullException"><paramref name="key"/> is <c>null</c>.</exception>
        /// <remarks>
        /// Unlike the Add for <see cref="IDictionary" />, the <see cref="MultiValueDictionary{TKey,TValue}"/> Add will not
        /// throw any exceptions. If the given <typeparamref name="TKey"/> is already in the <see cref="MultiValueDictionary{TKey,TValue}"/>,
        /// then <typeparamref name="TValue"/> will be added to <see cref="IReadOnlyCollection{TValue}"/> associated with <paramref name="key"/>
        /// </remarks>
        /// <remarks>
        /// A call to this Add method will always invalidate any currently running enumeration regardless
        /// of whether the Add method actually modified the <see cref="MultiValueDictionary{TKey, TValue}" />.
        /// </remarks>
        public void Add(TKey key, TValue value)
        {
            if (key == null)
                throw new ArgumentNullException(nameof(key));
            if (!_dictionary.TryGetValue(key, out InnerCollectionView collection))
            {
                collection = new InnerCollectionView(key, NewCollectionFactory());
                _dictionary.Add(key, collection);
            }
            collection.AddValue(value);
            _version++;
        }

        /// <summary>
        /// Adds a number of key-value pairs to this <see cref="MultiValueDictionary{TKey,TValue}"/>, where
        /// the key for each value is <paramref name="key"/>, and the value for a pair
        /// is an element from <paramref name="values"/>
        /// </summary>
        /// <param name="key">The <typeparamref name="TKey"/> of all entries to add</param>
        /// <param name="values">An <see cref="IEnumerable{TValue}"/> of values to add</param>
        /// <exception cref="ArgumentNullException"><paramref name="key"/> and <paramref name="values"/> must be non-null</exception>
        /// <remarks>
        /// A call to this AddRange method will always invalidate any currently running enumeration regardless
        /// of whether the AddRange method actually modified the <see cref="MultiValueDictionary{TKey,TValue}"/>.
        /// </remarks>
        public void AddRange(TKey key, IEnumerable<TValue> values)
        {
            if (key == null)
                throw new ArgumentNullException(nameof(key));
            if (values == null)
                throw new ArgumentNullException(nameof(values));

            if (!_dictionary.TryGetValue(key, out InnerCollectionView collection))
            {
                collection = new InnerCollectionView(key, NewCollectionFactory());
                _dictionary.Add(key, collection);
            }
            foreach (TValue value in values)
            {
                collection.AddValue(value);
            }
            _version++;
        }

        /// <summary>
        /// Removes every <typeparamref name="TValue"/> associated with the given <typeparamref name="TKey"/>
        /// from the <see cref="MultiValueDictionary{TKey,TValue}"/>.
        /// </summary>
        /// <param name="key">The <typeparamref name="TKey"/> of the elements to remove</param>
        /// <returns><c>true</c> if the removal was successful; otherwise <c>false</c></returns>
        /// <exception cref="ArgumentNullException"><paramref name="key"/> is <c>null</c>.</exception>
        public bool Remove(TKey key)
        {
            if (key == null)
                throw new ArgumentNullException(nameof(key));

            if (_dictionary.TryGetValue(key, out InnerCollectionView _) && _dictionary.Remove(key))
            {
                _version++;
                return true;
            }
            return false;
        }

        /// <summary>
        /// Removes the first instance (if any) of the given <typeparamref name="TKey"/>-<typeparamref name="TValue"/> 
        /// pair from this <see cref="MultiValueDictionary{TKey,TValue}"/>. 
        /// </summary>
        /// <param name="key">The <typeparamref name="TKey"/> of the element to remove</param>
        /// <param name="value">The <typeparamref name="TValue"/> of the element to remove</param>
        /// <exception cref="ArgumentNullException"><paramref name="key"/> must be non-null</exception>
        /// <returns><c>true</c> if the removal was successful; otherwise <c>false</c></returns>
        /// <remarks>
        /// If the <typeparamref name="TValue"/> being removed is the last one associated with its <typeparamref name="TKey"/>, then that 
        /// <typeparamref name="TKey"/> will be removed from the <see cref="MultiValueDictionary{TKey,TValue}"/> and its 
        /// associated <see cref="IReadOnlyCollection{TValue}"/> will be freed as if a call to <see cref="Remove(TKey)"/>
        /// had been made.
        /// </remarks>
        public bool Remove(TKey key, TValue value)
        {
            if (key == null)
                throw new ArgumentNullException(nameof(key));

            if (_dictionary.TryGetValue(key, out InnerCollectionView collection) && collection.RemoveValue(value))
            {
                if (collection.Count == 0)
                    _dictionary.Remove(key);
                _version++;
                return true;
            }
            return false;
        }

        /// <summary>
        /// Determines if the given <typeparamref name="TKey"/>-<typeparamref name="TValue"/> 
        /// pair exists within this <see cref="MultiValueDictionary{TKey,TValue}"/>.
        /// </summary>
        /// <param name="key">The <typeparamref name="TKey"/> of the element.</param>
        /// <param name="value">The <typeparamref name="TValue"/> of the element.</param>
        /// <returns><c>true</c> if found; otherwise <c>false</c></returns>
        /// <exception cref="ArgumentNullException"><paramref name="key"/> must be non-null</exception>
        public bool Contains(TKey key, TValue value)
        {
            if (key == null)
                throw new ArgumentNullException(nameof(key));

            return (_dictionary.TryGetValue(key, out InnerCollectionView collection) && collection.Contains(value));
        }

        /// <summary>
        /// Determines if the given <typeparamref name="TValue"/> exists within this <see cref="MultiValueDictionary{TKey,TValue}"/>.
        /// </summary>
        /// <param name="value">A <typeparamref name="TValue"/> to search the <see cref="MultiValueDictionary{TKey,TValue}"/> for</param>
        /// <returns><c>true</c> if the <see cref="MultiValueDictionary{TKey,TValue}"/> contains the <paramref name="value"/>; otherwise <c>false</c></returns>      
        public bool ContainsValue(TValue value)
        {
            foreach (InnerCollectionView sublist in _dictionary.Values)
                if (sublist.Contains(value))
                    return true;
            return false;
        }

        /// <summary>
        /// Removes every <typeparamref name="TKey"/> and <typeparamref name="TValue"/> from this 
        /// <see cref="MultiValueDictionary{TKey,TValue}"/>.
        /// </summary>
        public void Clear()
        {
            _dictionary.Clear();
            _version++;
        }

        #endregion

        #region Members implemented from IReadOnlyDictionary<TKey, IReadOnlyCollection<TValue>>
        /*======================================================================
        ** Members implemented from IReadOnlyDictionary<TKey, IReadOnlyCollection<TValue>>
        ======================================================================*/

        /// <summary>
        /// Determines if the given <typeparamref name="TKey"/> exists within this <see cref="MultiValueDictionary{TKey,TValue}"/> and has
        /// at least one <typeparamref name="TValue"/> associated with it.
        /// </summary>
        /// <param name="key">The <typeparamref name="TKey"/> to search the <see cref="MultiValueDictionary{TKey,TValue}"/> for</param>
        /// <returns><c>true</c> if the <see cref="MultiValueDictionary{TKey,TValue}"/> contains the requested <typeparamref name="TKey"/>;
        /// otherwise <c>false</c>.</returns>
        /// <exception cref="ArgumentNullException"><paramref name="key"/> must be non-null</exception>
        public bool ContainsKey(TKey key)
        {
            if (key == null)
                throw new ArgumentNullException(nameof(key));
            // Since modification to the MultiValueDictionary is only allowed through its own API, we
            // can ensure that if a collection is in the internal dictionary then it must have at least one
            // associated TValue, or else it would have been removed whenever its final TValue was removed.
            return _dictionary.ContainsKey(key);
        }

        /// <summary>
        /// Gets each <typeparamref name="TKey"/> in this <see cref="MultiValueDictionary{TKey,TValue}"/> that
        /// has one or more associated <typeparamref name="TValue"/>.
        /// </summary>
        /// <value>
        /// An <see cref="IEnumerable{TKey}"/> containing each <typeparamref name="TKey"/> 
        /// in this <see cref="MultiValueDictionary{TKey,TValue}"/> that has one or more associated 
        /// <typeparamref name="TValue"/>.
        /// </value>
        public IEnumerable<TKey> Keys => _dictionary.Keys;

        /// <summary>
        /// Attempts to get the <typeparamref name="TValue"/> associated with the given
        /// <typeparamref name="TKey"/> and place it into <paramref name="value"/>.
        /// </summary>
        /// <param name="key">The <typeparamref name="TKey"/> of the element to retrieve</param>
        /// <param name="value">
        /// When this method returns, contains the <typeparamref name="TValue"/> associated with the specified
        /// <typeparamref name="TKey"/> if it is found; otherwise contains the default value of <typeparamref name="TValue"/>.
        /// </param>
        /// <returns>
        /// <c>true</c> if the <see cref="MultiValueDictionary{TKey,TValue}"/> contains an element with the specified 
        /// <typeparamref name="TKey"/>; otherwise, <c>false</c>.
        /// </returns>
        /// <exception cref="ArgumentNullException"><paramref name="key"/> must be non-null</exception>
        public bool TryGetValue(TKey key, out IReadOnlyCollection<TValue> value)
        {
            if (key == null)
                throw new ArgumentNullException(nameof(key));

            var success = _dictionary.TryGetValue(key, out InnerCollectionView collection);
            value = collection;
            return success;
        }

        /// <summary>
        /// Gets an enumerable of <see cref="IReadOnlyCollection{TValue}"/> from this <see cref="MultiValueDictionary{TKey,TValue}"/>,
        /// where each <see cref="IReadOnlyCollection{TValue}" /> is the collection of every <typeparamref name="TValue"/> associated
        /// with a <typeparamref name="TKey"/> present in the <see cref="MultiValueDictionary{TKey,TValue}"/>. 
        /// </summary>
        /// <value>An IEnumerable of each <see cref="IReadOnlyCollection{TValue}"/> in this 
        /// <see cref="MultiValueDictionary{TKey,TValue}"/></value>
        public IEnumerable<IReadOnlyCollection<TValue>> Values => _dictionary.Values;

        /// <summary>
        /// Get every <typeparamref name="TValue"/> associated with the given <typeparamref name="TKey"/>. If 
        /// <paramref name="key"/> is not found in this <see cref="MultiValueDictionary{TKey,TValue}"/>, will 
        /// throw a <see cref="KeyNotFoundException"/>.
        /// </summary>
        /// <param name="key">The <typeparamref name="TKey"/> of the elements to retrieve.</param>
        /// <exception cref="ArgumentNullException"><paramref name="key"/> must be non-null</exception>
        /// <exception cref="KeyNotFoundException"><paramref name="key"/> does not have any associated 
        /// <typeparamref name="TValue"/>s in this <see cref="MultiValueDictionary{TKey,TValue}"/>.</exception>
        /// <value>
        /// An <see cref="IReadOnlyCollection{TValue}"/> containing every <typeparamref name="TValue"/>
        /// associated with <paramref name="key"/>.
        /// </value>
        /// <remarks>
        /// Note that the <see cref="IReadOnlyCollection{TValue}"/> returned will change alongside any changes 
        /// to the <see cref="MultiValueDictionary{TKey,TValue}"/> 
        /// </remarks>
        public IReadOnlyCollection<TValue> this[TKey key]
        {
            get
            {
                if (key == null)
                    throw new ArgumentNullException(nameof(key));

                if (_dictionary.TryGetValue(key, out InnerCollectionView collection))
                    return collection;

                throw new KeyNotFoundException();
            }
        }

        /// <summary>
        /// Returns the number of <typeparamref name="TKey"/>s with one or more associated <typeparamref name="TValue"/>
        /// in this <see cref="MultiValueDictionary{TKey,TValue}"/>.
        /// </summary>
        /// <value>The number of <typeparamref name="TKey"/>s in this <see cref="MultiValueDictionary{TKey,TValue}"/>.</value>
        public int Count => _dictionary.Count;

        /// <summary>
        /// Get an Enumerator over the <typeparamref name="TKey"/>-<see cref="IReadOnlyCollection{TValue}"/>
        /// pairs in this <see cref="MultiValueDictionary{TKey,TValue}"/>.
        /// </summary>
        /// <returns>an Enumerator over the <typeparamref name="TKey"/>-<see cref="IReadOnlyCollection{TValue}"/>
        /// pairs in this <see cref="MultiValueDictionary{TKey,TValue}"/>.</returns>
        public IEnumerator<KeyValuePair<TKey, IReadOnlyCollection<TValue>>> GetEnumerator() => new Enumerator(this);

        IEnumerator IEnumerable.GetEnumerator() => new Enumerator(this);

        #endregion

        /// <summary>
        /// The Enumerator class for a <see cref="MultiValueDictionary{TKey, TValue}"/>
        /// that iterates over <typeparamref name="TKey"/>-<see cref="IReadOnlyCollection{TValue}"/>
        /// pairs.
        /// </summary>
        private class Enumerator :
            IEnumerator<KeyValuePair<TKey, IReadOnlyCollection<TValue>>>
        {
            private readonly MultiValueDictionary<TKey, TValue> _multiValueDictionary;
            private readonly int _version;
            private Dictionary<TKey, InnerCollectionView>.Enumerator _enumerator;
            private EnumerationState _state;

            /// <summary>
            /// Constructor for the enumerator
            /// </summary>
            /// <param name="multiValueDictionary">A MultiValueDictionary to iterate over</param>
            internal Enumerator(MultiValueDictionary<TKey, TValue> multiValueDictionary)
            {
                _multiValueDictionary = multiValueDictionary;
                _version = multiValueDictionary._version;
                _enumerator = multiValueDictionary._dictionary.GetEnumerator();
                _state = EnumerationState.BeforeFirst;
                Current = default;
            }

            public KeyValuePair<TKey, IReadOnlyCollection<TValue>> Current { get; private set; }

            object IEnumerator.Current
            {
                get
                {
                    switch (_state)
                    {
                        case EnumerationState.BeforeFirst:
                            throw new InvalidOperationException((/*Strings.*/"InvalidOperation_EnumNotStarted"));
                        case EnumerationState.AfterLast:
                            throw new InvalidOperationException((/*Strings.*/"InvalidOperation_EnumEnded"));
                        default:
                            return Current;
                    }
                }
            }

            /// <summary>
            /// Advances the enumerator to the next element of the collection.
            /// </summary>
            /// <returns>
            /// true if the enumerator was successfully advanced to the next element; false if the enumerator has passed the end of the collection.
            /// </returns>
            /// <exception cref="T:System.InvalidOperationException">The collection was modified after the enumerator was created. </exception>
            public bool MoveNext()
            {
                if (_version != _multiValueDictionary._version)
                    throw new InvalidOperationException(/*Strings.*/"InvalidOperation_EnumFailedVersion");

                if (_enumerator.MoveNext())
                {
                    Current = new KeyValuePair<TKey, IReadOnlyCollection<TValue>>(_enumerator.Current.Key, _enumerator.Current.Value);
                    _state = EnumerationState.During;
                    return true;
                }

                Current = default;
                _state = EnumerationState.AfterLast;
                return false;
            }

            /// <summary>
            /// Sets the enumerator to its initial position, which is before the first element in the collection.
            /// </summary>
            /// <exception cref="T:System.InvalidOperationException">The collection was modified after the enumerator was created. </exception>
            public void Reset()
            {
                if (_version != _multiValueDictionary._version)
                    throw new InvalidOperationException(/*Strings.*/"InvalidOperation_EnumFailedVersion");
                _enumerator.Dispose();
                _enumerator = _multiValueDictionary._dictionary.GetEnumerator();
                Current = default;
                _state = EnumerationState.BeforeFirst;
            }

            /// <summary>
            /// Frees resources associated with this Enumerator
            /// </summary>
            public void Dispose() => _enumerator.Dispose();

            private enum EnumerationState
            {
                BeforeFirst,
                During,
                AfterLast
            }
        }

        /// <summary>
        /// An inner class that functions as a view of an ICollection within a MultiValueDictionary
        /// </summary>
        private class InnerCollectionView :
            ICollection<TValue>,
            IReadOnlyCollection<TValue>
        {
            private readonly ICollection<TValue> _collection;

            #region Private Concrete API
            /*======================================================================
            ** Private Concrete API
            ======================================================================*/

            public InnerCollectionView(TKey key, ICollection<TValue> collection)
            {
                Key = key;
                _collection = collection;
            }

            public void AddValue(TValue item) => _collection.Add(item);

            public bool RemoveValue(TValue item) => _collection.Remove(item);

            #endregion

            #region Shared API
            /*======================================================================
            ** Shared API
            ======================================================================*/

            public bool Contains(TValue item) => _collection.Contains(item);

            public void CopyTo(TValue[] array, int arrayIndex)
            {
                if (array == null)
                    throw new ArgumentNullException(nameof(array));
                if (arrayIndex < 0)
                    throw new ArgumentOutOfRangeException(nameof(arrayIndex), /*Strings.*/"ArgumentOutOfRange_NeedNonNegNum");
                if (arrayIndex > array.Length)
                    throw new ArgumentOutOfRangeException(nameof(arrayIndex), /*Strings.*/"ArgumentOutOfRange_Index");
                if (array.Length - arrayIndex < _collection.Count)
                    throw new ArgumentException(/*Strings.*/"CopyTo_ArgumentsTooSmall", nameof(arrayIndex));

                _collection.CopyTo(array, arrayIndex);
            }

            public int Count => _collection.Count;

            public bool IsReadOnly => true;

            public IEnumerator<TValue> GetEnumerator() => _collection.GetEnumerator();

            IEnumerator IEnumerable.GetEnumerator() => GetEnumerator();

            public TKey Key { get; }

            #endregion

            #region Public-Facing API
            /*======================================================================
            ** Public-Facing API
            ======================================================================*/

            void ICollection<TValue>.Add(TValue item) => throw new NotSupportedException(/*Strings.*/"ReadOnly_Modification");


            void ICollection<TValue>.Clear() => throw new NotSupportedException(/*Strings.*/"ReadOnly_Modification");

            bool ICollection<TValue>.Remove(TValue item) => throw new NotSupportedException(/*Strings.*/"ReadOnly_Modification");

            #endregion
        }
    }
}


#region Advanced - How to multi-target

// The NETx symbol is active when a query runs under .NET x or later.
// (LINQPad also recognizes NETx_0_OR_GREATER in case you enjoy typing.)

#if NET8
// Code that requires .NET 8 or later
#endif

#if NET7
// Code that requires .NET 7 or later
#endif

#if NET6
// Code that requires .NET 6 or later
#endif

#if NETCORE
// Code that requires .NET Core or later
#else
// Code that runs under .NET Framework (LINQPad 5)
#endif

#endregion